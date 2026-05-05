-- | Iv3 report types (verslagsoorten).
-- Municipalities submit budgets, quarterly reports, and annual accounts.
-- Keys include year prefix (e.g. \"2023X005\" = Jaarrekening 2023).
-- Source: dataderden.cbs.nl Verslagsoort dimension.
module DutchGov.Schema.Iv3ReportType
  ( Iv3ReportType(..)
  , Iv3ReportTypeId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
