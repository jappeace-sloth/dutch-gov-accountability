-- | Cost categories from the Iv3 classification.
-- Describes HOW money is spent: \"L1.1 Salarissen\", \"L4.2 Subsidies\",
-- \"L3.8 Overige goederen en diensten\", etc.
-- Source: dataderden.cbs.nl Categorie dimension.
module DutchGov.Schema.Iv3CostCategory
  ( Iv3CostCategory(..)
  , Iv3CostCategoryId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
