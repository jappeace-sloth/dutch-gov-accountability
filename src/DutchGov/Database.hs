{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Database
  ( withDatabase
  , upsertGovFunctions
  , upsertTransactions
  , upsertSectors
  , upsertPeriods
  , upsertExpenditures
  , upsertBudgetEntries
  , setScrapeMeta
  , getScrapeMeta
  ) where

import Control.Monad (forM_, void)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (runStdoutLoggingT)
import Data.Text (Text)
import Database.Persist.Sqlite

import DutchGov.Schema
import DutchGov.CBS.ODataResponse
import DutchGov.CBS.Client (CbsExpenditure(..))
import DutchGov.Rijksfinancien.BudgetTable (BudgetRow(..))

-- | Run a database action with connection pool and auto-migration.
withDatabase :: Text -> (ConnectionPool -> IO a) -> IO a
withDatabase dbPath action = runStdoutLoggingT $ do
  withSqlitePool dbPath 1 $ \pool -> do
    liftIO $ runSqlPool (runMigration migrateAll) pool
    liftIO $ action pool

-- | Upsert CBS government function dimension values.
upsertGovFunctions :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertGovFunctions values = forM_ values $ \val ->
  void $ upsertBy (UniqueCbsFunctionKey (ovKey val))
    GovFunction
      { govFunctionCbsKey = ovKey val
      , govFunctionTitle = ovTitle val
      , govFunctionDescription = ovDescription val
      , govFunctionCategoryGroupId = ovCategoryGroupId val
      }
    [ GovFunctionTitle =. ovTitle val
    , GovFunctionDescription =. ovDescription val
    , GovFunctionCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert CBS transaction dimension values.
upsertTransactions :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertTransactions values = forM_ values $ \val ->
  void $ upsertBy (UniqueCbsTransactionKey (ovKey val))
    CbsTransaction
      { cbsTransactionCbsKey = ovKey val
      , cbsTransactionTitle = ovTitle val
      , cbsTransactionDescription = ovDescription val
      , cbsTransactionCategoryGroupId = ovCategoryGroupId val
      }
    [ CbsTransactionTitle =. ovTitle val
    , CbsTransactionDescription =. ovDescription val
    , CbsTransactionCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert CBS sector dimension values.
upsertSectors :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertSectors values = forM_ values $ \val ->
  void $ upsertBy (UniqueSectorKey (ovKey val))
    Sector
      { sectorCbsKey = ovKey val
      , sectorTitle = ovTitle val
      , sectorDescription = ovDescription val
      , sectorCategoryGroupId = ovCategoryGroupId val
      }
    [ SectorTitle =. ovTitle val
    , SectorDescription =. ovDescription val
    , SectorCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert CBS period dimension values.
upsertPeriods :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertPeriods values = forM_ values $ \val ->
  void $ upsertBy (UniquePeriodKey (ovKey val))
    Period
      { periodCbsKey = ovKey val
      , periodTitle = ovTitle val
      , periodDescription = ovDescription val
      , periodStatus = Nothing
      }
    [ PeriodTitle =. ovTitle val
    , PeriodDescription =. ovDescription val
    ]

-- | Upsert CBS expenditure rows.
upsertExpenditures :: MonadIO m => [CbsExpenditure] -> SqlPersistT m ()
upsertExpenditures rows = forM_ rows $ \row ->
  void $ upsertBy (UniqueExpenditure (ceTransactionKey row) (ceFunctionKey row)
                                     (ceSectorKey row) (cePeriodKey row))
    Expenditure
      { expenditureTransactionKey = ceTransactionKey row
      , expenditureFunctionKey = ceFunctionKey row
      , expenditureSectorKey = ceSectorKey row
      , expenditurePeriodKey = cePeriodKey row
      , expenditureAmountMlnEur = ceAmountMlnEur row
      }
    [ ExpenditureAmountMlnEur =. ceAmountMlnEur row
    ]

-- | Upsert Rijksfinancien budget entries.
upsertBudgetEntries :: MonadIO m => Int -> Text -> [BudgetRow] -> SqlPersistT m ()
upsertBudgetEntries year phase rows = forM_ rows $ \row ->
  void $ upsertBy (UniqueBudgetEntry year phase (brChapterNumber row) (brArticleNumber row)
                                     (brSubArticleNumber row) (brInstrumentNumber row)
                                     (brRegulationNumber row) (brVuo row))
    BudgetEntry
      { budgetEntryYear = year
      , budgetEntryPhase = phase
      , budgetEntryMinister = brMinister row
      , budgetEntryChapterName = brChapterName row
      , budgetEntryChapterNumber = brChapterNumber row
      , budgetEntryArticleName = brArticleName row
      , budgetEntryArticleNumber = brArticleNumber row
      , budgetEntrySubArticleName = brSubArticleName row
      , budgetEntrySubArticleNumber = brSubArticleNumber row
      , budgetEntryInstrumentName = brInstrumentName row
      , budgetEntryInstrumentNumber = brInstrumentNumber row
      , budgetEntryRegulationName = brRegulationName row
      , budgetEntryRegulationNumber = brRegulationNumber row
      , budgetEntryVuo = brVuo row
      , budgetEntryAmount = brAmount row
      }
    [ BudgetEntryAmount =. brAmount row
    , BudgetEntryMinister =. brMinister row
    , BudgetEntryChapterName =. brChapterName row
    , BudgetEntryArticleName =. brArticleName row
    , BudgetEntrySubArticleName =. brSubArticleName row
    , BudgetEntryInstrumentName =. brInstrumentName row
    , BudgetEntryRegulationName =. brRegulationName row
    ]

-- | Set a metadata key-value pair (last scrape time, etc.)
setScrapeMeta :: MonadIO m => Text -> Text -> SqlPersistT m ()
setScrapeMeta metaKey metaValue =
  void $ upsertBy (UniqueMetaKey metaKey)
    ScrapeMeta { scrapeMetaKey = metaKey, scrapeMetaValue = metaValue }
    [ ScrapeMetaValue =. metaValue ]

-- | Get a metadata value by key.
getScrapeMeta :: MonadIO m => Text -> SqlPersistT m (Maybe Text)
getScrapeMeta metaKey = do
  result <- getBy (UniqueMetaKey metaKey)
  pure $ fmap (scrapeMetaValue . entityVal) result
