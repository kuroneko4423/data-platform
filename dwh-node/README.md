# 🏠 DWH Node

データウェアハウス機能を提供するノードです。

## 🏗️ 構成サービス

| サービス | ポート | 用途 |
|---------|--------|------|
| PostgreSQL | 5432 | データウェアハウス |
| Trino | 8080 | 分散SQLクエリエンジン |

## 📋 前提条件

**Storage Nodeが起動していること**（Trinoでの連携時）

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
./setup.sh logs postgres-dwh  # PostgreSQLのログ表示
./setup.sh psql       # PostgreSQLに接続
./setup.sh reset      # 全データ削除
```

## 🔐 デフォルト認証情報

### PostgreSQL DWH
| ユーザー | パスワード | 用途 | 権限 |
|---------|-----------|------|------|
| postgres | postgres123 | 管理用 | 全権限 |
| etl_user | etl123 | ETL処理用 | 全スキーマ書き込み |
| analyst | analyst123 | 分析用 | silver/gold/marts読み取り |
| readonly_user | readonly123 | 読み取り専用 | gold/martsのみ読み取り |

### Trino
- 認証なし（デフォルト設定）

## 🗂️ DWHスキーマ構成（メダリオンアーキテクチャ）

| スキーマ | 用途 | 説明 |
|---------|------|------|
| bronze | 生データ層 | データソースからの生データを格納 |
| silver | クレンジング層 | クレンジング・正規化済みデータ |
| gold | 集計層 | ビジネス向け集計データ |
| marts | データマート | 部門・用途別のデータマート |
| staging | 一時領域 | ETL処理用の一時領域 |

## 🔗 接続例

### psqlコマンド
```bash
# コンテナ内から接続
./setup.sh psql

# 外部から接続
psql -h <DWH_NODE_IP> -p 5432 -U analyst -d dwh
```

### Python (psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    host='<DWH_NODE_IP>',
    port=5432,
    database='dwh',
    user='analyst',
    password='analyst123'
)
```

### SQLAlchemy
```python
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://analyst:analyst123@<DWH_NODE_IP>:5432/dwh'
)
```

## 📊 Trinoカタログ

| カタログ名 | 接続先 | 説明 |
|-----------|--------|------|
| dwh | PostgreSQL DWH | 同一ノード内のDWH |
| minio | MinIO (S3) | Storage Nodeのデータレイク |
| storage | PostgreSQL | Storage Nodeのメタデータ/分析DB |

### Trino接続例
```bash
# Trino CLI
docker exec -it trino trino

# クエリ例
trino> SHOW CATALOGS;
trino> SHOW SCHEMAS FROM dwh;
trino> SELECT * FROM dwh.gold.dim_date LIMIT 10;
```

## 📁 ファイル構成

```
dwh-node/
├── docker-compose.yml
├── .env
├── setup.sh
├── README.md
├── postgresql/
│   └── postgresql.conf        # DWH用最適化設定
├── init-scripts/
│   └── 01-init-dwh.sql       # スキーマ・ユーザー初期化
└── trino/
    └── etc/
        ├── config.properties
        ├── jvm.config
        ├── log.properties
        ├── node.properties
        └── catalog/
            ├── dwh.properties
            ├── minio.properties.template
            └── storage.properties.template
```

## ⚙️ .env設定

```bash
# PostgreSQL DWH設定
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123

# Storage NodeのIPアドレス（Trino連携用）
STORAGE_NODE_IP=10.10.10.10
```

## 🔧 PostgreSQL DWH最適化設定

`postgresql/postgresql.conf`で以下の最適化が適用されています：

- **メモリ**: shared_buffers=8GB, work_mem=256MB
- **パラレルクエリ**: max_parallel_workers_per_gather=4
- **統計**: default_statistics_target=500
- **WAL**: max_wal_size=4GB

※32GB RAMを想定した設定です。環境に応じて調整してください。

## ⚠️ 注意事項

1. Storage Nodeとの連携にはTrinoカタログ設定が必要です
2. `./setup.sh configure`でTrinoカタログ設定が自動生成されます
3. 本番環境ではパスワードを変更してください
4. postgresql.confはメモリ量に応じて調整してください
