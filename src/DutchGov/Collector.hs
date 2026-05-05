{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Collector
  ( Source(..)
  , collectAll
  , collectCbs
  , collectRijksfinancien
  ) where

import Control.Monad (forM_)
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
import DutchGov.Rijksfinancien.Client

-- | Which public data source to collect from
data Source = SourceCbs | SourceRijksfinancien | SourceAll
  deriving (Show, Eq)

-- | Collect all requested public data sources into the database.
collectAll :: Source -> ConnectionPool -> IO ()
collectAll source pool = do
  manager <- newManager tlsManagerSettings
  case source of
    SourceCbs -> collectCbs manager pool
    SourceRijksfinancien -> collectRijksfinancien manager pool
    SourceAll -> do
      collectCbs manager pool
      collectRijksfinancien manager pool

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
