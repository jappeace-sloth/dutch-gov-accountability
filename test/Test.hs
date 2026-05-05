module Main (main) where

import Test.Tasty

import qualified DutchGov.CBS.ODataResponseTest
import qualified DutchGov.DatabaseTest
import qualified DutchGov.Iv3.ClientTest
import qualified DutchGov.Rijksfinancien.BudgetTableTest

main :: IO ()
main = defaultMain $ testGroup "dutch-gov-accountability"
  [ DutchGov.CBS.ODataResponseTest.tests
  , DutchGov.Rijksfinancien.BudgetTableTest.tests
  , DutchGov.DatabaseTest.tests
  , DutchGov.Iv3.ClientTest.tests
  ]
