{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Database
  ( withDatabase
  , upsertGovFunctions
  , upsertTransactions
  , upsertSectors
  , upsertPeriods
  , upsertExpenditures
  , upsertBudgetEntries
  , upsertIv3TaskFields
  , upsertIv3CostCategories
  , upsertIv3Municipalities
  , upsertIv3ReportTypes
  , upsertIv3MunicipalFinances
  , setSyncMeta
  , getSyncMeta
  ) where

import Control.Monad (forM_, void)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (runNoLoggingT)
import Data.Text (Text)
import Database.Persist.Sqlite

import DutchGov.Schema
import DutchGov.CBS.ODataResponse
import DutchGov.CBS.Client (CbsExpenditure(..))
import DutchGov.Iv3.Client (Iv3FinanceRow(..))
import DutchGov.Rijksfinancien.BudgetTable (BudgetRow(..))

-- | Run a database action with connection pool and auto-migration.
withDatabase :: Text -> (ConnectionPool -> IO a) -> IO a
withDatabase dbPath action = runNoLoggingT $ do
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

-- | Upsert CBS expenditure rows using raw INSERT OR REPLACE for speed.
upsertExpenditures :: MonadIO m => [CbsExpenditure] -> SqlPersistT m ()
upsertExpenditures rows = forM_ rows $ \row ->
  rawExecute
    "INSERT OR REPLACE INTO expenditure (transaction_key, function_key, sector_key, period_key, amount_mln_eur) VALUES (?, ?, ?, ?, ?)"
    [ PersistText (ceTransactionKey row)
    , PersistText (ceFunctionKey row)
    , PersistText (ceSectorKey row)
    , PersistText (cePeriodKey row)
    , maybe PersistNull PersistDouble (ceAmountMlnEur row)
    ]

-- | Upsert Rijksfinancien budget entries using raw INSERT OR REPLACE for speed.
upsertBudgetEntries :: MonadIO m => Int -> Text -> [BudgetRow] -> SqlPersistT m ()
upsertBudgetEntries year phase rows = forM_ rows $ \row ->
  rawExecute
    "INSERT OR REPLACE INTO budget_entry (year, phase, minister, chapter_name, chapter_number, article_name, article_number, sub_article_name, sub_article_number, instrument_name, instrument_number, regulation_name, regulation_number, vuo, amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    [ PersistInt64 (fromIntegral year)
    , PersistText phase
    , maybe PersistNull PersistText (brMinister row)
    , maybe PersistNull PersistText (brChapterName row)
    , PersistText (brChapterNumber row)
    , maybe PersistNull PersistText (brArticleName row)
    , PersistText (brArticleNumber row)
    , maybe PersistNull PersistText (brSubArticleName row)
    , PersistText (brSubArticleNumber row)
    , maybe PersistNull PersistText (brInstrumentName row)
    , PersistText (brInstrumentNumber row)
    , maybe PersistNull PersistText (brRegulationName row)
    , PersistText (brRegulationNumber row)
    , PersistText (brVuo row)
    , PersistInt64 (fromIntegral (brAmount row))
    ]

-- | Set a metadata key-value pair (last sync time, etc.)
setSyncMeta :: MonadIO m => Text -> Text -> SqlPersistT m ()
setSyncMeta metaKey metaValue =
  void $ upsertBy (UniqueMetaKey metaKey)
    SyncMeta { syncMetaKey = metaKey, syncMetaValue = metaValue }
    [ SyncMetaValue =. metaValue ]

-- | Get a metadata value by key.
getSyncMeta :: MonadIO m => Text -> SqlPersistT m (Maybe Text)
getSyncMeta metaKey = do
  result <- getBy (UniqueMetaKey metaKey)
  pure $ fmap (syncMetaValue . entityVal) result

-- | Upsert Iv3 task field dimension values.
upsertIv3TaskFields :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertIv3TaskFields values = forM_ values $ \val ->
  void $ upsertBy (UniqueIv3TaskFieldKey (ovKey val))
    Iv3TaskField
      { iv3TaskFieldCbsKey = ovKey val
      , iv3TaskFieldTitle = ovTitle val
      , iv3TaskFieldDescription = ovDescription val
      , iv3TaskFieldCategoryGroupId = ovCategoryGroupId val
      }
    [ Iv3TaskFieldTitle =. ovTitle val
    , Iv3TaskFieldDescription =. ovDescription val
    , Iv3TaskFieldCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert Iv3 cost category dimension values.
upsertIv3CostCategories :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertIv3CostCategories values = forM_ values $ \val ->
  void $ upsertBy (UniqueIv3CostCategoryKey (ovKey val))
    Iv3CostCategory
      { iv3CostCategoryCbsKey = ovKey val
      , iv3CostCategoryTitle = ovTitle val
      , iv3CostCategoryDescription = ovDescription val
      , iv3CostCategoryCategoryGroupId = ovCategoryGroupId val
      }
    [ Iv3CostCategoryTitle =. ovTitle val
    , Iv3CostCategoryDescription =. ovDescription val
    , Iv3CostCategoryCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert Iv3 municipality dimension values.
upsertIv3Municipalities :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertIv3Municipalities values = forM_ values $ \val ->
  void $ upsertBy (UniqueIv3MunicipalityKey (ovKey val))
    Iv3Municipality
      { iv3MunicipalityCbsKey = ovKey val
      , iv3MunicipalityTitle = ovTitle val
      , iv3MunicipalityDescription = ovDescription val
      , iv3MunicipalityCategoryGroupId = ovCategoryGroupId val
      }
    [ Iv3MunicipalityTitle =. ovTitle val
    , Iv3MunicipalityDescription =. ovDescription val
    , Iv3MunicipalityCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert Iv3 report type dimension values.
upsertIv3ReportTypes :: MonadIO m => [ODataValue] -> SqlPersistT m ()
upsertIv3ReportTypes values = forM_ values $ \val ->
  void $ upsertBy (UniqueIv3ReportTypeKey (ovKey val))
    Iv3ReportType
      { iv3ReportTypeCbsKey = ovKey val
      , iv3ReportTypeTitle = ovTitle val
      , iv3ReportTypeDescription = ovDescription val
      , iv3ReportTypeCategoryGroupId = ovCategoryGroupId val
      }
    [ Iv3ReportTypeTitle =. ovTitle val
    , Iv3ReportTypeDescription =. ovDescription val
    , Iv3ReportTypeCategoryGroupId =. ovCategoryGroupId val
    ]

-- | Upsert Iv3 municipal finance rows using raw INSERT OR REPLACE for speed.
upsertIv3MunicipalFinances :: MonadIO m => Int -> [Iv3FinanceRow] -> SqlPersistT m ()
upsertIv3MunicipalFinances year rows = forM_ rows $ \row ->
  rawExecute
    "INSERT OR REPLACE INTO iv3_municipal_finance (year, task_field_key, cost_category_key, municipality_key, report_type_key, amount_first_publication, amount_revised) VALUES (?, ?, ?, ?, ?, ?, ?)"
    [ PersistInt64 (fromIntegral year)
    , PersistText (iv3TaskFieldKey row)
    , PersistText (iv3CostCategoryKey row)
    , PersistText (iv3MunicipalityKey row)
    , PersistText (iv3ReportTypeKey row)
    , maybe PersistNull PersistDouble (iv3AmountFirst row)
    , maybe PersistNull PersistDouble (iv3AmountRevised row)
    ]
