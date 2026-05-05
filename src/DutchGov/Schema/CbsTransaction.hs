-- | Types of financial transactions in government spending (CBS 84122NED).
-- Describes WHAT kind of spending: \"D1 Beloning van werknemers\",
-- \"P2 Intermediair verbruik\", \"D7 Overige inkomensoverdrachten\".
module DutchGov.Schema.CbsTransaction
  ( CbsTransaction(..)
  , CbsTransactionId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
