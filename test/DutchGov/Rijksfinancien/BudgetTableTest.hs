{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Rijksfinancien.BudgetTableTest (tests) where

import Data.Aeson (eitherDecode)
import Test.Tasty
import Test.Tasty.HUnit

import DutchGov.Rijksfinancien.BudgetTable

tests :: TestTree
tests = testGroup "Rijksfinancien BudgetTable"
  [ testCase "parses full budget row" $ do
      let json = "[{\"begrotingsnaam\": \"Defensie\", \"hoofdstuk_naam\": \"Defensie\", \"hoofdstuk_nummer\": \"X\", \"artikel_naam\": \"Inzet\", \"artikel_nummer\": \"01\", \"subartikel_naam\": \"Gereedstelling\", \"subartikel_nummer\": \"01.01\", \"instrument_naam\": \"Bekostiging\", \"instrument_nummer\": \"01.01.01\", \"regeling_naam\": \"Materieeluitgaven\", \"regeling_nummer\": \"01.01.01.01\", \"vuo\": \"U\", \"bedrag\": 1500000}]"
      case eitherDecode json :: Either String [BudgetRow] of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right [row] -> do
          brMinister row @?= Just "Defensie"
          brChapterName row @?= Just "Defensie"
          brChapterNumber row @?= "X"
          brArticleName row @?= Just "Inzet"
          brArticleNumber row @?= "01"
          brSubArticleName row @?= Just "Gereedstelling"
          brSubArticleNumber row @?= "01.01"
          brInstrumentName row @?= Just "Bekostiging"
          brInstrumentNumber row @?= "01.01.01"
          brRegulationName row @?= Just "Materieeluitgaven"
          brRegulationNumber row @?= "01.01.01.01"
          brVuo row @?= "U"
          brAmount row @?= 1500000
        Right other -> assertFailure $ "Expected 1 row, got " ++ show (length other)

  , testCase "parses budget row with missing optional fields" $ do
      let json = "[{\"hoofdstuk_nummer\": \"IX\", \"artikel_nummer\": \"02\", \"subartikel_nummer\": \"02.01\", \"instrument_nummer\": \"02.01.01\", \"regeling_nummer\": \"02.01.01.01\", \"vuo\": \"O\", \"bedrag\": 500}]"
      case eitherDecode json :: Either String [BudgetRow] of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right [row] -> do
          brMinister row @?= Nothing
          brChapterName row @?= Nothing
          brChapterNumber row @?= "IX"
          brArticleName row @?= Nothing
          brArticleNumber row @?= "02"
          brVuo row @?= "O"
          brAmount row @?= 500
        Right other -> assertFailure $ "Expected 1 row, got " ++ show (length other)

  , testCase "parses multiple budget rows" $ do
      let json = "[{\"hoofdstuk_nummer\": \"A\", \"artikel_nummer\": \"01\", \"subartikel_nummer\": \"\", \"instrument_nummer\": \"\", \"regeling_nummer\": \"\", \"vuo\": \"U\", \"bedrag\": 100}, {\"hoofdstuk_nummer\": \"B\", \"artikel_nummer\": \"02\", \"subartikel_nummer\": \"\", \"instrument_nummer\": \"\", \"regeling_nummer\": \"\", \"vuo\": \"V\", \"bedrag\": 200}]"
      case eitherDecode json :: Either String [BudgetRow] of
        Left err -> assertFailure $ "Parse failed: " ++ err
        Right [row1, row2] -> do
          brChapterNumber row1 @?= "A"
          brAmount row1 @?= 100
          brChapterNumber row2 @?= "B"
          brAmount row2 @?= 200
          brVuo row2 @?= "V"
        Right other -> assertFailure $ "Expected 2 rows, got " ++ show (length other)
  ]
