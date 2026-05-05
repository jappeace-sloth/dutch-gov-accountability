{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CLI
  ( Command(..)
  , ScrapeOptions(..)
  , StatusOptions(..)
  , parseCommand
  ) where

import Data.Text (Text)
import Options.Applicative

import DutchGov.Scraper (Source(..))

data Command
  = Scrape ScrapeOptions
  | Status StatusOptions
  deriving (Show)

data ScrapeOptions = ScrapeOptions
  { scrapeDb     :: Text
  , scrapeSource :: Source
  } deriving (Show)

data StatusOptions = StatusOptions
  { statusDb :: Text
  } deriving (Show)

parseCommand :: IO Command
parseCommand = execParser opts
  where
    opts = info (commandParser <**> helper)
      ( fullDesc
      <> progDesc "Dutch government spending data scraper"
      <> header "dutch-gov-accountability - CBS + Rijksfinancien scraper"
      )

commandParser :: Parser Command
commandParser = subparser
  ( command "scrape" (info scrapeParser (progDesc "Scrape data from government APIs"))
  <> command "status" (info statusParser (progDesc "Show database status"))
  )

scrapeParser :: Parser Command
scrapeParser = Scrape <$> (ScrapeOptions
  <$> dbOption
  <*> sourceOption)

statusParser :: Parser Command
statusParser = Status <$> (StatusOptions <$> dbOption)

dbOption :: Parser Text
dbOption = strOption
  ( long "db"
  <> metavar "FILE"
  <> help "SQLite database file path"
  <> value "spending.db"
  <> showDefault
  )

sourceOption :: Parser Source
sourceOption = option readSource
  ( long "source"
  <> metavar "SOURCE"
  <> help "Data source to scrape: cbs, rijksfinancien, or all"
  <> value SourceAll
  <> showDefault
  )

readSource :: ReadM Source
readSource = eitherReader $ \s -> case s of
  "cbs"             -> Right SourceCbs
  "rijksfinancien"  -> Right SourceRijksfinancien
  "all"             -> Right SourceAll
  other             -> Left $ "Unknown source: " ++ other
                           ++ ". Expected cbs, rijksfinancien, or all."
