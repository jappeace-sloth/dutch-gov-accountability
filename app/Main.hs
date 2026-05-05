{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import qualified Data.Text as Text
import Database.Persist.Sqlite (runSqlPool)

import DutchGov.CLI
import DutchGov.Database (withDatabase, getScrapeMeta)
import DutchGov.Scraper (scrapeAll)

main :: IO ()
main = do
  cmd <- parseCommand
  case cmd of
    Scrape opts -> do
      withDatabase (scrapeDb opts) $ \pool ->
        scrapeAll (scrapeSource opts) pool
    Status opts -> do
      withDatabase (statusDb opts) $ \pool -> do
        cbsTime <- runSqlPool (getScrapeMeta "cbs_last_scrape") pool
        rfjTime <- runSqlPool (getScrapeMeta "rijksfinancien_last_scrape") pool
        putStrLn "Database status:"
        putStrLn $ "  CBS last scrape: " ++ maybe "never" Text.unpack cbsTime
        putStrLn $ "  Rijksfinancien last scrape: " ++ maybe "never" Text.unpack rfjTime
