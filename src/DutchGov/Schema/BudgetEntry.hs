-- | Central government budget entries from rijksfinancien.nl.
-- Hierarchical: minister → chapter → article → sub-article → instrument → regulation.
-- Tracks planned and actual spending per budget phase (OWB, O1, O2, JV).
module DutchGov.Schema.BudgetEntry
  ( BudgetEntry(..)
  , BudgetEntryId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
