-- | Government expenditure fact table from CBS dataset 84122NED.
-- Each row links a transaction type × function × sector × period to an amount.
-- Amounts in millions of euros. Aggregate national-level data.
module DutchGov.Schema.Expenditure
  ( Expenditure(..)
  , ExpenditureId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
