-- | Key-value store for tracking sync timestamps.
-- Records when each data source was last collected successfully.
module DutchGov.Schema.SyncMeta
  ( SyncMeta(..)
  , SyncMetaId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
