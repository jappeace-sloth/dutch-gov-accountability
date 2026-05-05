{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CBS.Client
  ( CbsExpenditure(..)
  , fetchDimension
  , fetchExpenditures
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

-- | Fetch all expenditure rows, following pagination links.
-- Calls the callback with each page of results.
fetchExpenditures :: MonadIO m
                  => Manager
                  -> Int -- ^ Page size ($top parameter)
                  -> (ODataResponse CbsExpenditure -> m ())
                  -> m (Either String ())
fetchExpenditures manager pageSize processPage = do
  let initialUrl = cbsBaseUrl ++ "TypedDataSet?$top=" ++ show pageSize
  fetchPages initialUrl
  where
    fetchPages url = do
      result <- liftIO $ do
        request <- parseRequest url
        response <- httpLbs request manager
        case statusCode (responseStatus response) of
          200 -> pure (Right (responseBody response))
          code -> pure (Left $ "HTTP " ++ show code ++ " fetching expenditures")
      case result of
        Left err -> pure (Left err)
        Right body -> case eitherDecode body of
          Left err -> pure (Left err)
          Right odata -> do
            processPage odata
            case odataNextLink odata of
              Nothing -> pure (Right ())
              Just nextUrl -> fetchPages (Text.unpack nextUrl)

