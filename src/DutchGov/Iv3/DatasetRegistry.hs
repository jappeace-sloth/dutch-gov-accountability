{-# LANGUAGE OverloadedStrings #-}

-- | Mapping from year to CBS dataderden dataset identifier.
-- Each year of Iv3 data has a separate dataset on dataderden.cbs.nl.
-- Dataset IDs are stable CBS identifiers.
module DutchGov.Iv3.DatasetRegistry
  ( iv3DatasetForYear
  , iv3AvailableYears
  ) where

import Data.Text (Text)

-- | Look up the CBS dataderden dataset ID for a given year.
-- Returns Nothing if the year is not available.
iv3DatasetForYear :: Int -> Maybe Text
iv3DatasetForYear year = case year of
  2010 -> Just "45e01"
  2011 -> Just "45e02"
  2012 -> Just "45e03"
  2013 -> Just "45e04"
  2014 -> Just "45e05"
  2015 -> Just "45e06"
  2016 -> Just "45e07"
  2017 -> Just "45e08"
  2018 -> Just "45e09"
  2019 -> Just "45e10"
  2020 -> Just "45e11"
  2021 -> Just "45e12"
  2022 -> Just "45e13"
  2023 -> Just "45e14"
  2024 -> Just "45e15"
  2025 -> Just "45e16"
  2026 -> Just "45e17"
  _    -> Nothing

-- | All years for which Iv3 datasets are known.
iv3AvailableYears :: [Int]
iv3AvailableYears = [2010..2026]
