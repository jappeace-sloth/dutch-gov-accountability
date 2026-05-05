{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Iv3.ClientTest (tests) where

import Data.Aeson (eitherDecode)
import qualified Data.ByteString.Lazy.Char8 as LBS
import Test.Tasty
import Test.Tasty.HUnit

import DutchGov.Iv3.Client (Iv3FinanceRow(..))
import DutchGov.CBS.ODataResponse (ODataResponse(..), ODataValue(..))

tests :: TestTree
tests = testGroup "Iv3 Client"
  [ testCase "parse Iv3 finance row with both amounts" $ do
      let json = LBS.pack $ unlines
            [ "{"
            , "  \"TaakveldBalanspost\": \"TV5.4  \","
            , "  \"Categorie\": \"L3.8    \","
            , "  \"Gemeenten\": \"GM0363  \","
            , "  \"Verslagsoort\": \"2023X005\","
            , "  \"EerstePublicatie_1\": 1234.0,"
            , "  \"Bijgesteld_2\": 1250.5"
            , "}"
            ]
      case eitherDecode json of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right row -> do
          iv3TaskFieldKey row @?= "TV5.4"
          iv3CostCategoryKey row @?= "L3.8"
          iv3MunicipalityKey row @?= "GM0363"
          iv3ReportTypeKey row @?= "2023X005"
          iv3AmountFirst row @?= Just 1234.0
          iv3AmountRevised row @?= Just 1250.5

  , testCase "parse Iv3 finance row with null amounts" $ do
      let json = LBS.pack $ unlines
            [ "{"
            , "  \"TaakveldBalanspost\": \"TV0.1\","
            , "  \"Categorie\": \"L1.1\","
            , "  \"Gemeenten\": \"GM0599\","
            , "  \"Verslagsoort\": \"2022X003\","
            , "  \"EerstePublicatie_1\": null,"
            , "  \"Bijgesteld_2\": null"
            , "}"
            ]
      case eitherDecode json of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right row -> do
          iv3TaskFieldKey row @?= "TV0.1"
          iv3MunicipalityKey row @?= "GM0599"
          iv3AmountFirst row @?= Nothing
          iv3AmountRevised row @?= Nothing

  , testCase "parse Iv3 finance row with missing amount fields" $ do
      let json = LBS.pack $ unlines
            [ "{"
            , "  \"TaakveldBalanspost\": \"TV7.1\","
            , "  \"Categorie\": \"L4.2\","
            , "  \"Gemeenten\": \"GM0518\","
            , "  \"Verslagsoort\": \"2021X005\""
            , "}"
            ]
      case eitherDecode json of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right row -> do
          iv3TaskFieldKey row @?= "TV7.1"
          iv3CostCategoryKey row @?= "L4.2"
          iv3AmountFirst row @?= Nothing
          iv3AmountRevised row @?= Nothing

  , testCase "parse Iv3 dimension response strips whitespace from keys" $ do
      let json = LBS.pack $ unlines
            [ "{"
            , "  \"value\": ["
            , "    {"
            , "      \"Key\": \"GM0363  \","
            , "      \"Title\": \"Amsterdam\","
            , "      \"Description\": \"Gemeente Amsterdam\","
            , "      \"CategoryGroupID\": 2"
            , "    },"
            , "    {"
            , "      \"Key\": \"GM0599\","
            , "      \"Title\": \"Rotterdam\""
            , "    }"
            , "  ]"
            , "}"
            ]
      case eitherDecode json of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> do
          let vals = odataValue (odata :: ODataResponse ODataValue)
          length vals @?= 2
          ovKey (vals !! 0) @?= "GM0363  "
          ovTitle (vals !! 0) @?= "Amsterdam"
          ovDescription (vals !! 0) @?= Just "Gemeente Amsterdam"
          ovCategoryGroupId (vals !! 0) @?= Just 2
          ovKey (vals !! 1) @?= "GM0599"
          ovTitle (vals !! 1) @?= "Rotterdam"
          ovDescription (vals !! 1) @?= Nothing

  , testCase "keys are stripped during Iv3FinanceRow parsing" $ do
      let json = LBS.pack $ unlines
            [ "{"
            , "  \"TaakveldBalanspost\": \"  TV5.4  \","
            , "  \"Categorie\": \"L3.8   \","
            , "  \"Gemeenten\": \"  GM0363\","
            , "  \"Verslagsoort\": \"2023X005  \""
            , "}"
            ]
      case eitherDecode json of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right row -> do
          iv3TaskFieldKey row @?= "TV5.4"
          iv3CostCategoryKey row @?= "L3.8"
          iv3MunicipalityKey row @?= "GM0363"
          iv3ReportTypeKey row @?= "2023X005"
  ]
