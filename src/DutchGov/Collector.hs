{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Collector
  ( Source(..)
  , Iv3Options(..)
  , defaultIv3Options
  , collectAll
  , collectCbs
  , collectRijksfinancien
  , collectIv3
  ) where

import Control.Monad (forM_, when)
import Data.IORef (newIORef, readIORef, modifyIORef')
import qualified Data.Text as Text
import System.IO (hFlush, stdout)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Database.Persist.Sqlite (ConnectionPool, runSqlPool)
import Network.HTTP.Client (Manager, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)

import DutchGov.CBS.Client
import DutchGov.CBS.ODataResponse (ODataValue(..))
import DutchGov.Database
import DutchGov.Iv3.Client (fetchIv3Dimension, fetchIv3MunicipalityData, stripODataValue)
import DutchGov.Iv3.DatasetRegistry
import DutchGov.Rijksfinancien.Client

-- | Which public data source to collect from
data Source
  = SourceCbs
  | SourceRijksfinancien
  | SourceIv3
  | SourceAll
  deriving (Show, Eq)

-- | Options for Iv3 collection (year range).
data Iv3Options = Iv3Options
  { iv3FromYear :: Int
  , iv3ToYear   :: Int
  , iv3Enabled  :: Bool
  } deriving (Show, Eq)

-- | Default Iv3 options: 2020–2026, enabled.
defaultIv3Options :: Iv3Options
defaultIv3Options = Iv3Options
  { iv3FromYear = 2020
  , iv3ToYear = 2026
  , iv3Enabled = True
  }

-- | Collect all requested public data sources into the database.
collectAll :: Source -> Iv3Options -> ConnectionPool -> IO ()
collectAll source iv3Opts pool = do
  manager <- newManager tlsManagerSettings
  case source of
    SourceCbs -> collectCbs manager pool
    SourceRijksfinancien -> collectRijksfinancien manager pool
    SourceIv3 -> collectIv3 manager iv3Opts pool
    SourceAll -> do
      collectCbs manager pool
      collectRijksfinancien manager pool
      when (iv3Enabled iv3Opts) $ collectIv3 manager iv3Opts pool

-- | Collect CBS 84122NED dataset (dimensions + expenditures).
-- The CBS API does not support $skip pagination, so we fetch expenditures
-- by iterating over all period × sector combinations (~180 requests).
collectCbs :: Manager -> ConnectionPool -> IO ()
collectCbs manager pool = do
  putStrLn "Collecting CBS dimensions..."

  -- Fetch and store dimension tables, keeping keys for iteration
  periodKeys <- fetchAndStore "Perioden" (\vals -> runSqlPool (upsertPeriods vals) pool)
  sectorKeys <- fetchAndStore "Sectoren" (\vals -> runSqlPool (upsertSectors vals) pool)
  fetchAndStore_ "Overheidsfuncties" (\vals -> runSqlPool (upsertGovFunctions vals) pool)
  fetchAndStore_ "Transacties" (\vals -> runSqlPool (upsertTransactions vals) pool)

  putStrLn $ "Collecting CBS expenditures (" ++ show (length periodKeys)
           ++ " periods × " ++ show (length sectorKeys) ++ " sectors)..."

  let totalSlices = length periodKeys * length sectorKeys
  slicesDone <- newIORef (0 :: Int)
  errorCount <- newIORef (0 :: Int)

  forM_ periodKeys $ \periodKey ->
    forM_ sectorKeys $ \sectorKey -> do
      result <- fetchExpenditureSlice manager periodKey sectorKey
      case result of
        Left err -> do
          modifyIORef' errorCount (+1)
          putStrLn $ "  Error " ++ Text.unpack periodKey ++ "/" ++ Text.unpack sectorKey
                   ++ ": " ++ err
        Right rows -> do
          runSqlPool (upsertExpenditures rows) pool
          modifyIORef' slicesDone (+1)
          done <- readIORef slicesDone
          putStr $ "\r  " ++ show done ++ "/" ++ show totalSlices
                 ++ " slices (" ++ show (length rows) ++ " rows last)"
          hFlush stdout

  errors <- readIORef errorCount
  putStrLn $ "\nCBS collection complete. Errors: " ++ show errors
  now <- getCurrentTime
  let timestamp = Text.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now
  runSqlPool (setSyncMeta "cbs_last_sync" timestamp) pool
  where
    fetchAndStore :: String -> ([ODataValue] -> IO ()) -> IO [Text.Text]
    fetchAndStore dimension storeAction = do
      result <- fetchDimension manager dimension
      case result of
        Left err -> do
          putStrLn $ "Error fetching " ++ dimension ++ ": " ++ err
          pure []
        Right vals -> do
          storeAction vals
          putStrLn $ "  " ++ dimension ++ ": " ++ show (length vals) ++ " entries"
          pure (map ovKey vals)

    fetchAndStore_ :: String -> ([ODataValue] -> IO ()) -> IO ()
    fetchAndStore_ dimension storeAction = do
      result <- fetchDimension manager dimension
      case result of
        Left err -> putStrLn $ "Error fetching " ++ dimension ++ ": " ++ err
        Right vals -> do
          storeAction vals
          putStrLn $ "  " ++ dimension ++ ": " ++ show (length vals) ++ " entries"

-- | Collect Rijksfinancien budget tables for all years and phases.
collectRijksfinancien :: Manager -> ConnectionPool -> IO ()
collectRijksfinancien manager pool = do
  putStrLn "Collecting Rijksfinancien budget tables..."
  let years = [2015..2026] :: [Int]
  let phases = [minBound..maxBound] :: [Phase]

  forM_ years $ \year -> do
    forM_ phases $ \phase -> do
      result <- fetchBudgetTable manager year phase
      case result of
        Left err -> putStrLn $ "  Error year=" ++ show year
                             ++ " phase=" ++ show phase ++ ": " ++ err
        Right Nothing -> pure () -- 404, phase not available
        Right (Just rows) -> do
          let phaseText = phaseToText phase
          runSqlPool (upsertBudgetEntries year phaseText rows) pool
          putStrLn $ "  " ++ show year ++ "/" ++ show phase
                   ++ ": " ++ show (length rows) ++ " entries"

  now <- getCurrentTime
  let timestamp = Text.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now
  runSqlPool (setSyncMeta "rijksfinancien_last_sync" timestamp) pool
  putStrLn "Rijksfinancien collection complete."

-- | Collect Iv3 municipal finance data from dataderden.cbs.nl.
-- Fetches dimension tables (shared across years), then iterates over
-- municipalities per year to fetch finance data.
collectIv3 :: Manager -> Iv3Options -> ConnectionPool -> IO ()
collectIv3 manager iv3Opts pool = do
  let yearRange = filter (\y -> y >= iv3FromYear iv3Opts && y <= iv3ToYear iv3Opts)
                         iv3AvailableYears
  putStrLn $ "Collecting Iv3 municipal finances (" ++ show (length yearRange) ++ " years)..."

  forM_ yearRange $ \year -> do
    case iv3DatasetForYear year of
      Nothing -> putStrLn $ "  No dataset for year " ++ show year ++ ", skipping."
      Just datasetId -> do
        putStrLn $ "  Year " ++ show year ++ " (dataset " ++ Text.unpack datasetId ++ ")..."

        -- Fetch dimensions from this year's dataset
        taskFieldResult <- fetchIv3Dimension manager datasetId "TaakveldBalanspost"
        costCatResult   <- fetchIv3Dimension manager datasetId "Categorie"
        muniResult      <- fetchIv3Dimension manager datasetId "Gemeenten"
        reportResult    <- fetchIv3Dimension manager datasetId "Verslagsoort"

        case (taskFieldResult, costCatResult, muniResult, reportResult) of
          (Right taskFields, Right costCats, Right munis, Right reports) -> do
            -- Store dimensions with stripped keys
            runSqlPool (upsertIv3TaskFields (map stripODataValue taskFields)) pool
            runSqlPool (upsertIv3CostCategories (map stripODataValue costCats)) pool
            runSqlPool (upsertIv3Municipalities (map stripODataValue munis)) pool
            runSqlPool (upsertIv3ReportTypes (map stripODataValue reports)) pool
            putStrLn $ "    Dimensions: " ++ show (length taskFields) ++ " tasks, "
                     ++ show (length costCats) ++ " categories, "
                     ++ show (length munis) ++ " municipalities, "
                     ++ show (length reports) ++ " report types"

            -- Fetch finance data per municipality × report type
            -- (each combination ≤10K rows, fits single request)
            let muniKeys = map ovKey munis
                reportKeys = map ovKey reports
                totalQueries = length muniKeys * length reportKeys
            errorCount <- newIORef (0 :: Int)
            rowCount <- newIORef (0 :: Int)
            queryCount <- newIORef (0 :: Int)

            forM_ muniKeys $ \muniKey ->
              forM_ reportKeys $ \reportKey -> do
                result <- fetchIv3MunicipalityData manager datasetId muniKey reportKey
                case result of
                  Left err -> do
                    modifyIORef' errorCount (+1)
                    putStrLn $ "    Error " ++ Text.unpack muniKey ++ "/" ++ Text.unpack reportKey ++ ": " ++ err
                  Right rows -> do
                    runSqlPool (upsertIv3MunicipalFinances year rows) pool
                    modifyIORef' rowCount (+ length rows)
                    modifyIORef' queryCount (+1)
                    done <- readIORef queryCount
                    putStr $ "\r    " ++ show done ++ "/" ++ show totalQueries
                           ++ " queries (" ++ show (length rows) ++ " rows last)"
                    hFlush stdout

            errors <- readIORef errorCount
            totalRows <- readIORef rowCount
            putStrLn $ "\n    Year " ++ show year ++ " complete: "
                     ++ show totalRows ++ " rows, " ++ show errors ++ " errors"

          (Left err, _, _, _) -> putStrLn $ "    Error fetching task fields: " ++ err
          (_, Left err, _, _) -> putStrLn $ "    Error fetching cost categories: " ++ err
          (_, _, Left err, _) -> putStrLn $ "    Error fetching municipalities: " ++ err
          (_, _, _, Left err) -> putStrLn $ "    Error fetching report types: " ++ err

  now <- getCurrentTime
  let timestamp = Text.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now
  runSqlPool (setSyncMeta "iv3_last_sync" timestamp) pool
  putStrLn "Iv3 collection complete."
