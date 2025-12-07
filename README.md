# データ分析基盤環境 (Docker)

MinIO、PostgreSQL、Apache Airflowを使用したデータ分析基盤環境です。

## 構成

| サービス | 説明 | ポート | URL |
|---------|------|--------|-----|
| **MinIO** | S3互換オブジェクトストレージ | 9000 (API), 9001 (Console) | http://localhost:9001 |
| **PostgreSQL** | リレーショナルデータベース | 5432 | - |
| **Airflow Webserver** | ワークフロー管理UI | 8080 | http://localhost:8080 |
| **Airflow Scheduler** | DAGスケジューラー | - | - |
| **Airflow Triggerer** | 非同期トリガー | - | - |

## クイックスタート

### 1. 環境準備

```bash
# 必要なディレクトリを作成
mkdir -p dags logs plugins data

# Airflow用のUID設定（Linux環境）
echo "AIRFLOW_UID=$(id -u)" > .env
```

### 2. 起動

```bash
# 初回起動（バックグラウンド実行）
docker-compose up -d

# ログ確認
docker-compose logs -f
```

### 3. 初期化完了の確認

```bash
# 全サービスの状態確認
docker-compose ps
```

## アクセス情報

### MinIO Console
- **URL**: http://localhost:9001
- **ユーザー名**: `minioadmin`
- **パスワード**: `minioadmin`

初期バケット:
- `raw-data` - 生データ用
- `processed-data` - 処理済みデータ用
- `airflow-logs` - Airflowログ用

### Airflow Web UI
- **URL**: http://localhost:8080
- **ユーザー名**: `admin`
- **パスワード**: `admin`

### PostgreSQL
- **ホスト**: `localhost`
- **ポート**: `5432`
- **ユーザー名**: `airflow`
- **パスワード**: `airflow`
- **データベース**: `airflow` (メタデータ用), `datawarehouse` (分析用)

```bash
# 接続例
psql -h localhost -p 5432 -U airflow -d datawarehouse
```

## ディレクトリ構造

```
.
├── docker-compose.yml      # Docker Compose設定
├── .env                    # 環境変数
├── dags/                   # Airflow DAGファイル
│   └── sample_etl_pipeline.py
├── logs/                   # Airflowログ
├── plugins/                # Airflowプラグイン
├── data/                   # 共有データ
└── init-scripts/           # PostgreSQL初期化スクリプト
    └── 01-init-databases.sh
```

## PostgreSQL スキーマ構成

`datawarehouse` データベースには以下のスキーマが作成されます：

- **raw**: 生データ格納用
- **staging**: 中間処理データ用
- **mart**: 分析用マート

## Airflow Connections設定

### PostgreSQL接続
Airflow UIで以下の接続を設定してください：

1. **Admin → Connections → + ボタン**
2. 以下を入力:
   - Connection Id: `postgres_default`
   - Connection Type: `Postgres`
   - Host: `postgres`
   - Schema: `datawarehouse`
   - Login: `airflow`
   - Password: `airflow`
   - Port: `5432`

### MinIO (S3)接続
1. **Admin → Connections → + ボタン**
2. 以下を入力:
   - Connection Id: `minio_default`
   - Connection Type: `Amazon Web Services`
   - Extra:
   ```json
   {
     "aws_access_key_id": "minioadmin",
     "aws_secret_access_key": "minioadmin",
     "endpoint_url": "http://minio:9000"
   }
   ```

## 操作コマンド

```bash
# 起動
docker-compose up -d

# 停止
docker-compose down

# 停止（データも削除）
docker-compose down -v

# ログ確認
docker-compose logs -f [サービス名]

# 特定サービスの再起動
docker-compose restart airflow-webserver

# サービス状態確認
docker-compose ps
```

## トラブルシューティング

### Airflowが起動しない場合
```bash
# 初期化を再実行
docker-compose down
docker-compose up airflow-init
docker-compose up -d
```

### MinIOへの接続エラー
```bash
# MinIOの状態確認
docker-compose logs minio
docker-compose logs minio-init
```

### PostgreSQLへの接続エラー
```bash
# PostgreSQLの状態確認
docker-compose exec postgres pg_isready -U airflow
```

## カスタマイズ

### 認証情報の変更

`.env` ファイルを作成して環境変数を設定:

```env
AIRFLOW_UID=1000
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=your_secure_password
```

### リソース制限

`docker-compose.yml` に以下を追加:

```yaml
services:
  airflow-webserver:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
