-- =============================================================================
-- PostgreSQL DWH 初期化スクリプト
-- データウェアハウス用のスキーマとユーザーを作成
-- =============================================================================

-- ETL用ユーザー（書き込み権限あり）
CREATE USER etl_user WITH ENCRYPTED PASSWORD 'etl123';

-- 分析用ユーザー（読み取り中心）
CREATE USER analyst WITH ENCRYPTED PASSWORD 'analyst123';

-- 読み取り専用ユーザー
CREATE USER readonly_user WITH ENCRYPTED PASSWORD 'readonly123';

-- =============================================================================
-- DWHスキーマ構成（メダリオンアーキテクチャ）
-- =============================================================================

-- Bronze層（生データ）
CREATE SCHEMA IF NOT EXISTS bronze;
COMMENT ON SCHEMA bronze IS 'Raw data layer - データソースからの生データ';

-- Silver層（クレンジング済み）
CREATE SCHEMA IF NOT EXISTS silver;
COMMENT ON SCHEMA silver IS 'Cleansed data layer - クレンジング・正規化済みデータ';

-- Gold層（集計・分析用）
CREATE SCHEMA IF NOT EXISTS gold;
COMMENT ON SCHEMA gold IS 'Aggregated data layer - ビジネス向け集計データ';

-- Marts（データマート）
CREATE SCHEMA IF NOT EXISTS marts;
COMMENT ON SCHEMA marts IS 'Data marts - 部門・用途別のデータマート';

-- Staging（一時領域）
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Staging area - ETL処理用の一時領域';

-- =============================================================================
-- 権限設定
-- =============================================================================

-- ETLユーザー：全スキーマに対する全権限
GRANT ALL PRIVILEGES ON SCHEMA bronze, silver, gold, marts, staging TO etl_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA bronze, silver, gold, marts, staging TO etl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA bronze, silver, gold, marts, staging 
    GRANT ALL PRIVILEGES ON TABLES TO etl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA bronze, silver, gold, marts, staging 
    GRANT ALL PRIVILEGES ON SEQUENCES TO etl_user;

-- 分析ユーザー：Silver/Gold/Martsへの読み取り権限
GRANT USAGE ON SCHEMA silver, gold, marts TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA silver, gold, marts TO analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA silver, gold, marts 
    GRANT SELECT ON TABLES TO analyst;

-- 読み取り専用ユーザー：Gold/Martsのみ
GRANT USAGE ON SCHEMA gold, marts TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA gold, marts TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA gold, marts 
    GRANT SELECT ON TABLES TO readonly_user;

-- =============================================================================
-- 分析用拡張機能
-- =============================================================================

-- UUID生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 暗号化関数
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 統計関数の拡張
CREATE EXTENSION IF NOT EXISTS "tablefunc";

-- =============================================================================
-- サンプルテーブル（Gold層）
-- =============================================================================

-- 日付ディメンション
CREATE TABLE IF NOT EXISTS gold.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE gold.dim_date IS '日付ディメンションテーブル';

-- 日付ディメンションにデータ投入（2020-2030年）
INSERT INTO gold.dim_date (date_key, full_date, year, quarter, month, month_name, week, day_of_month, day_of_week, day_name, is_weekend)
SELECT 
    TO_CHAR(d, 'YYYYMMDD')::INTEGER as date_key,
    d as full_date,
    EXTRACT(YEAR FROM d)::INTEGER as year,
    EXTRACT(QUARTER FROM d)::INTEGER as quarter,
    EXTRACT(MONTH FROM d)::INTEGER as month,
    TO_CHAR(d, 'Month') as month_name,
    EXTRACT(WEEK FROM d)::INTEGER as week,
    EXTRACT(DAY FROM d)::INTEGER as day_of_month,
    EXTRACT(DOW FROM d)::INTEGER as day_of_week,
    TO_CHAR(d, 'Day') as day_name,
    EXTRACT(DOW FROM d) IN (0, 6) as is_weekend
FROM generate_series('2020-01-01'::date, '2030-12-31'::date, '1 day'::interval) as d
ON CONFLICT (date_key) DO NOTHING;

-- =============================================================================
-- ヘルスチェック用関数
-- =============================================================================

CREATE OR REPLACE FUNCTION public.health_check()
RETURNS TEXT AS $$
BEGIN
    RETURN 'OK';
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.health_check() TO PUBLIC;

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE 'DWH initialization completed successfully!';
END $$;
