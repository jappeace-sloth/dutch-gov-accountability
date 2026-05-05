{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Scraper
  ( Source(..)
  , scrapeAll
  , scrapeCbs
  , scrapeRijksfinancien
  ) where

import Control.Monad (forM_)
import qualified Data.Text as Text
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Database.Persist.Sqlite (ConnectionPool, runSqlPool)
import Network.HTTP.Client (Manager, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)

import DutchGov.CBS.Client
import DutchGov.CBS.ODataResponse (odataValue)
import DutchGov.Database
import DutchGov.Rijksfinancien.Client

-- | Which data source to scrape
data Source = SourceCbs | SourceRijksfinancien | SourceAll
  deriving (Show, Eq)

-- | Scrape all requested sources into the database.
scrapeAll :: Source -> ConnectionPool -> IO ()
scrapeAll source pool = do
  manager <- newManager tlsManagerSettings
  case source of
    SourceCbs -> scrapeCbs manager pool
    SourceRijksfinancien -> scrapeRijksfinancien manager pool
    SourceAll -> do
      scrapeCbs manager pool
      scrapeRijksfinancien manager pool

-- | Scrape CBS 84122NED dataset (dimensions + expenditures).
scrapeCbs :: Manager -> ConnectionPool -> IO ()
scrapeCbs manager pool = do
  putStrLn "Scraping CBS dimensions..."

  -- Fetch and store dimension tables
  fetchAndStore "Overheidsfuncties" (\vals -> runSqlPool (upsertGovFunctions vals) pool)
  fetchAndStore "Transacties" (\vals -> runSqlPool (upsertTransactions vals) pool)
  fetchAndStore "Sectoren" (\vals -> runSqlPool (upsertSectors vals) pool)
  fetchAndStore "Perioden" (\vals -> runSqlPool (upsertPeriods vals) pool)

  putStrLn "Scraping CBS expenditures..."
  pageCount <- fetchExpenditures manager 5000 $ \odata -> do
    runSqlPool (upsertExpenditures (odataValue odata)) pool
    putStr "."
  case pageCount of
    Left err -> putStrLn $ "\nError fetching expenditures: " ++ err
    Right () -> do
      putStrLn "\nCBS scrape complete."
      now <- getCurrentTime
      let timestamp = Text.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S" now
      runSqlPool (setScrapeMeta "cbs_last_scrape" timestamp) pool
  where
    fetchAndStore dimension storeAction = do
      result <- fetchDimension manager dimension
      case result of
        Left err -> putStrLn $ "Error fetching " ++ dimension ++ ": " ++ err
        Right vals -> do
          _ <- storeAction vals
          putStrLn $ "  " ++ dimension ++ ": " ++ show (length vals) ++ " entries"

-- | Scrape Rijksfinancien budget tables for all years and phases.
scrapeRijksfinancien :: Manager -> ConnectionPool -> IO ()
scrapeRijksfinancien manager pool = do
  putStrLn "Scraping Rijksfinancien budget tables..."
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
  runSqlPool (setScrapeMeta "rijksfinancien_last_scrape" timestamp) pool
  putStrLn "Rijksfinancien scrape complete."
