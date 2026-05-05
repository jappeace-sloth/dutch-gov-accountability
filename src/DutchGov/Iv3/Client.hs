{-# LANGUAGE OverloadedStrings #-}

-- | HTTP client for the Iv3 municipal finance data on CBS dataderden.
-- Fetches dimension tables (task fields, cost categories, municipalities,
-- report types) and fact data (municipal finance rows) per year.
module DutchGov.Iv3.Client
  ( Iv3FinanceRow(..)
  , iv3BaseUrl
  , fetchIv3Dimension
  , fetchIv3MunicipalityData
  ) where

import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as Text
import Network.HTTP.Client
import Network.HTTP.Types.Status (statusCode)

import DutchGov.CBS.ODataResponse (ODataResponse(..), ODataValue(..))

-- | Base URL for a dataderden OData dataset.
iv3BaseUrl :: Text -> String
iv3BaseUrl datasetId =
  "https://dataderden.cbs.nl/ODataApi/OData/" ++ Text.unpack datasetId ++ "/"

-- | A single row from the Iv3 TypedDataSet.
-- Contains keys for all dimensions plus the two amount columns.
data Iv3FinanceRow = Iv3FinanceRow
  { iv3TaskFieldKey    :: Text
  , iv3CostCategoryKey :: Text
  , iv3MunicipalityKey :: Text
  , iv3ReportTypeKey   :: Text
  , iv3AmountFirst     :: Maybe Double
  , iv3AmountRevised   :: Maybe Double
  } deriving (Show, Eq)

instance FromJSON Iv3FinanceRow where
  parseJSON = withObject "Iv3FinanceRow" $ \obj -> do
    taskField <- obj .: "TaakveldBalanspost"
    costCat   <- obj .: "Categorie"
    muni      <- obj .: "Gemeenten"
    report    <- obj .: "Verslagsoort"
    first     <- obj .:? "EerstePublicatie_1"
    revised   <- obj .:? "Bijgesteld_2"
    pure Iv3FinanceRow
      { iv3TaskFieldKey    = Text.strip taskField
      , iv3CostCategoryKey = Text.strip costCat
      , iv3MunicipalityKey = Text.strip muni
      , iv3ReportTypeKey   = Text.strip report
      , iv3AmountFirst     = first
      , iv3AmountRevised   = revised
      }

-- | Fetch a dimension table from a dataderden Iv3 dataset.
-- Dimension names: \"TaakveldBalanspost\", \"Categorie\", \"Gemeenten\", \"Verslagsoort\".
fetchIv3Dimension :: Manager -> Text -> String -> IO (Either String [ODataValue])
fetchIv3Dimension manager datasetId dimension = do
  let url = iv3BaseUrl datasetId ++ dimension ++ "?$format=json"
  request <- parseRequest url
  response <- httpLbs request manager
  case statusCode (responseStatus response) of
    200 -> case eitherDecode (responseBody response) of
      Right odata -> pure (Right (map stripODataValue (odataValue odata)))
      Left err    -> pure (Left err)
    code -> pure (Left $ "HTTP " ++ show code ++ " fetching Iv3 " ++ dimension)

-- | Fetch municipal finance data filtered by municipality key.
-- Most municipalities have <10K rows which fits in a single request.
fetchIv3MunicipalityData :: Manager -> Text -> Text -> IO (Either String [Iv3FinanceRow])
fetchIv3MunicipalityData manager datasetId municipalityKey = do
  let url = iv3BaseUrl datasetId ++ "TypedDataSet?$format=json&$filter=Gemeenten eq '"
              ++ Text.unpack municipalityKey ++ "'"
  request <- parseRequest url
  response <- httpLbs request manager
  case statusCode (responseStatus response) of
    200 -> case eitherDecode (responseBody response) of
      Right odata -> pure (Right (odataValue odata))
      Left err    -> pure (Left err)
    code -> pure (Left $ "HTTP " ++ show code ++ " fetching Iv3 data for "
                        ++ Text.unpack municipalityKey)

-- | Strip trailing whitespace from ODataValue keys (CBS pads with spaces).
stripODataValue :: ODataValue -> ODataValue
stripODataValue val = val { ovKey = Text.strip (ovKey val) }
