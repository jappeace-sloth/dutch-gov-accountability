-- | COFOG government function classification from CBS dataset 84122NED.
-- Hierarchical: \"1. Algemeen overheidsbestuur\" → \"1.1 Uitvoerende/wetgevende organen\".
-- Used as a dimension in the Expenditure fact table.
module DutchGov.Schema.GovFunction
  ( GovFunction(..)
  , GovFunctionId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
