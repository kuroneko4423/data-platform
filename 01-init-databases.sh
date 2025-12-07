#!/bin/bash
set -e

# 追加のデータベースを作成
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- データウェアハウス用データベース作成
    CREATE DATABASE datawarehouse;
    GRANT ALL PRIVILEGES ON DATABASE datawarehouse TO $POSTGRES_USER;

    -- datawarehouseデータベースに接続してスキーマ作成
    \c datawarehouse
    CREATE SCHEMA IF NOT EXISTS raw;
    CREATE SCHEMA IF NOT EXISTS staging;
    CREATE SCHEMA IF NOT EXISTS mart;

    -- サンプルテーブル作成
    CREATE TABLE IF NOT EXISTS raw.sample_data (
        id SERIAL PRIMARY KEY,
        data JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS mart.aggregated_data (
        id SERIAL PRIMARY KEY,
        metric_name VARCHAR(255),
        metric_value NUMERIC,
        aggregated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
EOSQL

echo "Additional databases and schemas created successfully!"
