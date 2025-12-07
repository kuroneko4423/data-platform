-- =============================================================================
-- PostgreSQL初期化スクリプト
-- 各サービス用のデータベースとユーザーを作成
-- =============================================================================

-- Airflow用データベース
CREATE DATABASE airflow;
CREATE USER airflow WITH ENCRYPTED PASSWORD 'airflow123';
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
ALTER DATABASE airflow OWNER TO airflow;

-- Superset用データベース
CREATE DATABASE superset;
CREATE USER superset WITH ENCRYPTED PASSWORD 'superset123';
GRANT ALL PRIVILEGES ON DATABASE superset TO superset;
ALTER DATABASE superset OWNER TO superset;

-- Metabase用データベース
CREATE DATABASE metabase;
CREATE USER metabase WITH ENCRYPTED PASSWORD 'metabase123';
GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase;
ALTER DATABASE metabase OWNER TO metabase;

-- 分析用データベース
CREATE DATABASE analytics;
CREATE USER analyst WITH ENCRYPTED PASSWORD 'analyst123';
GRANT ALL PRIVILEGES ON DATABASE analytics TO analyst;
ALTER DATABASE analytics OWNER TO analyst;

-- Hive Metastore用（Trinoで使用）
CREATE DATABASE hive_metastore;
CREATE USER hive WITH ENCRYPTED PASSWORD 'hive123';
GRANT ALL PRIVILEGES ON DATABASE hive_metastore TO hive;
ALTER DATABASE hive_metastore OWNER TO hive;

-- 権限付与
\c airflow
GRANT ALL ON SCHEMA public TO airflow;

\c superset
GRANT ALL ON SCHEMA public TO superset;

\c metabase
GRANT ALL ON SCHEMA public TO metabase;

\c analytics
GRANT ALL ON SCHEMA public TO analyst;
