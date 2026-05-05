-- | Municipal task fields from the Iv3 classification (BBV taakvelden).
-- Each field represents a policy area that municipalities report spending on,
-- such as \"5.4 Musea\", \"0.1 Bestuur\", \"7.1 Volksgezondheid\".
-- Source: dataderden.cbs.nl TaakveldBalanspost dimension.
module DutchGov.Schema.Iv3TaskField
  ( Iv3TaskField(..)
  , Iv3TaskFieldId
  , EntityField(..)
  , Unique(..)
  ) where

import DutchGov.Schema
