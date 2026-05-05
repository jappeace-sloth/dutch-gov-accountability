-- | Dutch municipalities (gemeenten).
-- Keys follow CBS coding: \"GM0363\" = Amsterdam, \"GM0599\" = Rotterdam, etc.
-- Set changes over time due to municipal mergers but keys are stable.
-- Source: dataderden.cbs.nl Gemeenten dimension.
module DutchGov.Schema.Iv3Municipality
  ( Iv3Municipality(..)
  , Iv3MunicipalityId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
