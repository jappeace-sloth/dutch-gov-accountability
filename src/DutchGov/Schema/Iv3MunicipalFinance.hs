-- | Municipal financial data — the core fact table for Iv3.
-- Each row represents one municipality's spending/revenue for a specific
-- task field and cost category, in a specific report period.
-- Amounts are in thousands of euros. Both initial and revised figures stored.
-- Source: dataderden.cbs.nl TypedDataSet (per-year datasets).
module DutchGov.Schema.Iv3MunicipalFinance
  ( Iv3MunicipalFinance(..)
  , Iv3MunicipalFinanceId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
