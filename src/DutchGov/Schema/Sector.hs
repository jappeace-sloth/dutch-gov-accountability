-- | Government sectors from CBS 84122NED.
-- Which level of government: \"Overheid\" (total), \"Rijksoverheid\",
-- \"Lokale overheid\", \"Sociale verzekeringsinstellingen\".
module DutchGov.Schema.Sector
  ( Sector(..)
  , SectorId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
