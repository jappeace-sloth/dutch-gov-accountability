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
  2010 -> Just "45007NED"
  2011 -> Just "45008NED"
  2012 -> Just "45001NED"
  2013 -> Just "45004NED"
  2014 -> Just "45005NED"
  2015 -> Just "45006NED"
  2016 -> Just "45031NED"
  2017 -> Just "45038NED"
  2018 -> Just "45042NED"
  2019 -> Just "45046NED"
  2020 -> Just "45050NED"
  2021 -> Just "45054NED"
  2022 -> Just "45059NED"
  2023 -> Just "45063NED"
  2024 -> Just "45067NED"
  2025 -> Just "45071NED"
  2026 -> Just "45078NED"
  _    -> Nothing

-- | All years for which Iv3 datasets are known.
iv3AvailableYears :: [Int]
iv3AvailableYears = [2010..2026]
