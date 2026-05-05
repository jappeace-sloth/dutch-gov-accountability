{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CBS.ODataResponse
  ( ODataResponse(..)
  , ODataValue(..)
  ) where

import Data.Aeson
import Data.Text (Text)

-- | Generic OData response envelope with pagination support.
-- The CBS API returns {"odata.nextLink": "...", "value": [...]}
data ODataResponse a = ODataResponse
  { odataNextLink :: Maybe Text
  , odataValue    :: [a]
  } deriving (Show, Eq)

instance FromJSON a => FromJSON (ODataResponse a) where
  parseJSON = withObject "ODataResponse" $ \obj -> do
    nextLink <- obj .:? "odata.nextLink"
    values <- obj .: "value"
    pure ODataResponse
      { odataNextLink = nextLink
      , odataValue = values
      }

-- | A single dimension value from CBS (Overheidsfuncties, Transacties, etc.)
data ODataValue = ODataValue
  { ovKey             :: Text
  , ovTitle           :: Text
  , ovDescription     :: Maybe Text
  , ovCategoryGroupId :: Maybe Int
  } deriving (Show, Eq)

instance FromJSON ODataValue where
  parseJSON = withObject "ODataValue" $ \obj -> do
    key <- obj .: "Key"
    title <- obj .: "Title"
    desc <- obj .:? "Description"
    catGroup <- obj .:? "CategoryGroupID"
    pure ODataValue
      { ovKey = key
      , ovTitle = title
      , ovDescription = desc
      , ovCategoryGroupId = catGroup
      }
