{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CBS.ODataResponseTest (tests) where

import Data.Aeson (eitherDecode)
import Test.Tasty
import Test.Tasty.HUnit

import DutchGov.CBS.ODataResponse
import DutchGov.CBS.Client (CbsExpenditure(..))

tests :: TestTree
tests = testGroup "CBS ODataResponse"
  [ testCase "parses dimension response with values" $ do
      let json = "{\"odata.nextLink\": null, \"value\": [{\"Key\": \"A012345\", \"Title\": \"Defensie\", \"Description\": \"Military\", \"CategoryGroupID\": 3}]}"
      case eitherDecode json :: Either String (ODataResponse ODataValue) of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> do
          odataNextLink odata @?= Nothing
          case odataValue odata of
            [val] -> do
              ovKey val @?= "A012345"
              ovTitle val @?= "Defensie"
              ovDescription val @?= Just "Military"
              ovCategoryGroupId val @?= Just 3
            other -> assertFailure $ "Expected 1 value, got " ++ show (length other)

  , testCase "parses response with pagination link" $ do
      let json = "{\"odata.nextLink\": \"https://opendata.cbs.nl/next?skip=5000\", \"value\": []}"
      case eitherDecode json :: Either String (ODataResponse ODataValue) of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> do
          odataNextLink odata @?= Just "https://opendata.cbs.nl/next?skip=5000"
          odataValue odata @?= []

  , testCase "parses expenditure row with amount" $ do
      let json = "{\"value\": [{\"Transacties\": \"T001\", \"Overheidsfuncties\": \"F001\", \"Sectoren\": \"S001\", \"Perioden\": \"2023JJ00\", \"Uitgaven_1\": 42.5}]}"
      case eitherDecode json :: Either String (ODataResponse CbsExpenditure) of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> case odataValue odata of
          [row] -> do
            ceTransactionKey row @?= "T001"
            ceFunctionKey row @?= "F001"
            ceSectorKey row @?= "S001"
            cePeriodKey row @?= "2023JJ00"
            ceAmountMlnEur row @?= Just 42.5
          other -> assertFailure $ "Expected 1 row, got " ++ show (length other)

  , testCase "parses expenditure row with null amount" $ do
      let json = "{\"value\": [{\"Transacties\": \"T001\", \"Overheidsfuncties\": \"F001\", \"Sectoren\": \"S001\", \"Perioden\": \"2023JJ00\", \"Uitgaven_1\": null}]}"
      case eitherDecode json :: Either String (ODataResponse CbsExpenditure) of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> case odataValue odata of
          [row] -> ceAmountMlnEur row @?= Nothing
          other -> assertFailure $ "Expected 1 row, got " ++ show (length other)

  , testCase "parses dimension value with missing optional fields" $ do
      let json = "{\"value\": [{\"Key\": \"X001\", \"Title\": \"Test\"}]}"
      case eitherDecode json :: Either String (ODataResponse ODataValue) of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right odata -> case odataValue odata of
          [val] -> do
            ovKey val @?= "X001"
            ovTitle val @?= "Test"
            ovDescription val @?= Nothing
            ovCategoryGroupId val @?= Nothing
          other -> assertFailure $ "Expected 1 value, got " ++ show (length other)
  ]
