{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CLI
  ( Command(..)
  , CollectOptions(..)
  , StatusOptions(..)
  , parseCommand
  ) where

import Data.Text (Text)
import Options.Applicative

import DutchGov.Collector (Source(..), Iv3Options(..))

data Command
  = Collect CollectOptions
  | Status StatusOptions
  deriving (Show)

data CollectOptions = CollectOptions
  { collectDb     :: Text
  , collectSource :: Source
  , collectIv3Options :: Iv3Options
  } deriving (Show)

data StatusOptions = StatusOptions
  { statusDb :: Text
  } deriving (Show)

parseCommand :: IO Command
parseCommand = execParser opts
  where
    opts = info (commandParser <**> helper)
      ( fullDesc
      <> progDesc "Dutch government public spending data collector"
      <> header "dutch-gov-accountability - CBS + Rijksfinancien + Iv3 open data collector"
      )

commandParser :: Parser Command
commandParser = subparser
  ( command "collect" (info collectParser (progDesc "Collect data from public government APIs"))
  <> command "status" (info statusParser (progDesc "Show database status"))
  )

collectParser :: Parser Command
collectParser = Collect <$> (CollectOptions
  <$> dbOption
  <*> sourceOption
  <*> iv3OptionsParser)

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
  <> help "Data source to collect: cbs, rijksfinancien, iv3, or all"
  <> value SourceAll
  <> showDefault
  )

readSource :: ReadM Source
readSource = eitherReader $ \s -> case s of
  "cbs"             -> Right SourceCbs
  "rijksfinancien"  -> Right SourceRijksfinancien
  "iv3"             -> Right SourceIv3
  "all"             -> Right SourceAll
  other             -> Left $ "Unknown source: " ++ other
                           ++ ". Expected cbs, rijksfinancien, iv3, or all."

iv3OptionsParser :: Parser Iv3Options
iv3OptionsParser = Iv3Options
  <$> option auto
      ( long "iv3-from"
      <> metavar "YEAR"
      <> help "Iv3 start year (inclusive)"
      <> value 2020
      <> showDefault
      )
  <*> option auto
      ( long "iv3-to"
      <> metavar "YEAR"
      <> help "Iv3 end year (inclusive)"
      <> value 2026
      <> showDefault
      )
  <*> fmap not (switch
      ( long "no-iv3"
      <> help "Exclude Iv3 from 'all' source collection"
      ))
