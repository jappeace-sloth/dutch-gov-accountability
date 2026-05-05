{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module DutchGov.Schema where

import Database.Persist.TH
import Data.Text (Text)

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
GovFunction
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueCbsFunctionKey cbsKey
    deriving Show Eq

CbsTransaction
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueCbsTransactionKey cbsKey
    deriving Show Eq

Sector
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueSectorKey cbsKey
    deriving Show Eq

Period
    cbsKey Text
    title Text
    description Text Maybe
    status Text Maybe
    UniquePeriodKey cbsKey
    deriving Show Eq

Expenditure
    transactionKey Text
    functionKey Text
    sectorKey Text
    periodKey Text
    amountMlnEur Double Maybe
    UniqueExpenditure transactionKey functionKey sectorKey periodKey
    deriving Show Eq

BudgetEntry
    year Int
    phase Text
    minister Text Maybe
    chapterName Text Maybe
    chapterNumber Text
    articleName Text Maybe
    articleNumber Text
    subArticleName Text Maybe
    subArticleNumber Text
    instrumentName Text Maybe
    instrumentNumber Text
    regulationName Text Maybe
    regulationNumber Text
    vuo Text
    amount Int
    UniqueBudgetEntry year phase chapterNumber articleNumber subArticleNumber instrumentNumber regulationNumber vuo
    deriving Show Eq

SyncMeta
    key Text
    value Text
    UniqueMetaKey key
    deriving Show Eq

Iv3TaskField
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueIv3TaskFieldKey cbsKey
    deriving Show Eq

Iv3CostCategory
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueIv3CostCategoryKey cbsKey
    deriving Show Eq

Iv3Municipality
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueIv3MunicipalityKey cbsKey
    deriving Show Eq

Iv3ReportType
    cbsKey Text
    title Text
    description Text Maybe
    categoryGroupId Int Maybe
    UniqueIv3ReportTypeKey cbsKey
    deriving Show Eq

Iv3MunicipalFinance
    year Int
    taskFieldKey Text
    costCategoryKey Text
    municipalityKey Text
    reportTypeKey Text
    amountFirstPublication Double Maybe
    amountRevised Double Maybe
    UniqueIv3Finance year taskFieldKey costCategoryKey municipalityKey reportTypeKey
    deriving Show Eq
|]
