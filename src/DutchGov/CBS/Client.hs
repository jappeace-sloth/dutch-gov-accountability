{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CBS.Client
  ( CbsExpenditure(..)
  , fetchDimension
  , fetchExpenditureSlice
  , cbsBaseUrl
  ) where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as Text
import Network.HTTP.Client
import Network.HTTP.Types.Status (statusCode)

import DutchGov.CBS.ODataResponse

cbsBaseUrl :: String
cbsBaseUrl = "https://opendata.cbs.nl/ODataApi/OData/84122NED/"

-- | Raw expenditure row from the CBS TypedDataSet
data CbsExpenditure = CbsExpenditure
  { ceTransactionKey :: Text
  , ceFunctionKey    :: Text
  , ceSectorKey      :: Text
  , cePeriodKey      :: Text
  , ceAmountMlnEur   :: Maybe Double
  } deriving (Show, Eq)

instance FromJSON CbsExpenditure where
  parseJSON = withObject "CbsExpenditure" $ \obj -> do
    transKey <- obj .: "Transacties"
    funcKey <- obj .: "Overheidsfuncties"
    secKey <- obj .: "Sectoren"
    perKey <- obj .: "Perioden"
    amount <- obj .:? "Uitgaven_1"
    pure CbsExpenditure
      { ceTransactionKey = transKey
      , ceFunctionKey = funcKey
      , ceSectorKey = secKey
      , cePeriodKey = perKey
      , ceAmountMlnEur = amount
      }

-- | Fetch a CBS dimension table (e.g. "Overheidsfuncties", "Transacties").
-- Returns all values (these tables are small, no pagination needed).
fetchDimension :: MonadIO m => Manager -> String -> m (Either String [ODataValue])
fetchDimension manager dimension = liftIO $ do
  let url = cbsBaseUrl ++ dimension
  request <- parseRequest url
  response <- httpLbs request manager
  case statusCode (responseStatus response) of
    200 -> case eitherDecode (responseBody response) of
      Right odata -> pure (Right (odataValue odata))
      Left err    -> pure (Left err)
    code -> pure (Left $ "HTTP " ++ show code ++ " fetching " ++ dimension)

-- | Fetch expenditure rows for a specific period and sector combination.
-- The CBS API doesn't support $skip pagination, so we filter by
-- period + sector to get chunks small enough to return in one request
-- (~1680 rows per combination).
fetchExpenditureSlice :: MonadIO m
                      => Manager
                      -> Text -- ^ Period key (e.g. "2023JJ00")
                      -> Text -- ^ Sector key (e.g. "A044938")
                      -> m (Either String [CbsExpenditure])
fetchExpenditureSlice manager periodKey sectorKey = liftIO $ do
  let url = cbsBaseUrl ++ "TypedDataSet?$filter=Perioden eq '"
              ++ Text.unpack periodKey ++ "' and Sectoren eq '"
              ++ Text.unpack sectorKey ++ "'"
  request <- parseRequest url
  response <- httpLbs request manager
  case statusCode (responseStatus response) of
    200 -> case eitherDecode (responseBody response) of
      Right odata -> pure (Right (odataValue odata))
      Left err    -> pure (Left err)
    code -> pure (Left $ "HTTP " ++ show code ++ " fetching expenditures for "
                        ++ Text.unpack periodKey ++ "/" ++ Text.unpack sectorKey)
