# 🏠 DWH Node

データウェアハウス機能を提供するノードです。

## 🏗️ 構成サービス

| サービス | ポート | 用途 |
|---------|--------|------|
| ClickHouse | 8123 (HTTP), 9000 (Native) | 列指向OLAP データベース |
| Trino | 8080 | 分散SQLクエリエンジン |

## 📋 前提条件

**Storage Nodeが起動していること**

Storage NodeのIPアドレスを確認してください。

## 🚀 セットアップ

```bash
# 1. 実行権限を付与
chmod +x setup.sh

# 2. Dockerの確認
./setup.sh check

# 3. 設定ファイル生成（Storage Node IPを入力）
./setup.sh configure

# 4. サービスを起動
./setup.sh start
```

## 📋 コマンド一覧

```bash
./setup.sh check      # Dockerの確認・インストール
./setup.sh configure  # 設定ファイル生成
./setup.sh start      # サービスを起動
./setup.sh stop       # サービスを停止
./setup.sh restart    # サービスを再起動
./setup.sh status     # ステータス表示
./setup.sh logs       # 全ログ表示
./setup.sh logs clickhouse  # ClickHouseのログ表示
./setup.sh reset      # 全データ削除
```

## 🔐 デフォルト認証情報

### ClickHouse
| ユーザー | パスワード | 用途 |
|---------|-----------|------|
| default | clickhouse123 | 管理用 |
| analyst | analyst123 | 分析用 |
| etl_user | etl123 | ETL用 |
| readonly_user | readonly123 | 読み取り専用 |

### Trino
- 認証なし（デフォルト設定）

## 🔗 接続例

### ClickHouse CLI
```bash
docker exec -it clickhouse clickhouse-client --password clickhouse123
```

### ClickHouse HTTP API
```bash
curl "http://localhost:8123/?query=SELECT%201"
```

### Trino CLI
```bash
docker exec -it trino trino
```

## 📊 Trinoカタログ

| カタログ名 | 接続先 | 説明 |
|-----------|--------|------|
| clickhouse | ClickHouse | 同一ノード内のClickHouse |
| minio | MinIO (S3) | Storage Nodeのデータレイク |
| postgresql | PostgreSQL | Storage Nodeの分析DB |

## 🗂️ ClickHouseデータベース作成例

```sql
-- データベース作成
CREATE DATABASE IF NOT EXISTS analytics;

-- テーブル作成
CREATE TABLE analytics.sample_data (
    id UInt64,
    timestamp DateTime,
    value Float64,
    category String
) ENGINE = MergeTree()
ORDER BY (timestamp, id);
```

## 📁 ファイル構成

```
dwh-node/
├── docker-compose.yml
├── .env
├── setup.sh
├── README.md
├── clickhouse/
│   ├── config.xml
│   └── users.xml
└── trino/
    └── etc/
        ├── config.properties
        ├── jvm.config
        ├── log.properties
        ├── node.properties
        └── catalog/
            ├── clickhouse.properties
            ├── minio.properties.template
            └── postgresql.properties.template
```

## ⚙️ .env設定

```bash
# ClickHouse設定
CLICKHOUSE_DB=default
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=clickhouse123

# Storage NodeのIPアドレス（必須）
STORAGE_NODE_IP=10.10.10.10
```

## ⚠️ 注意事項

1. Storage Nodeが先に起動している必要があります
2. `.env`の`STORAGE_NODE_IP`を正しく設定してください
3. `./setup.sh configure`でTrinoカタログ設定が自動生成されます
