# 🔄 ETL Node

データパイプライン管理機能を提供するノードです。

## 🏗️ 構成サービス

| サービス | ポート | 用途 |
|---------|--------|------|
| Airflow Webserver | 8080 | ワークフロー管理UI |
| Airflow Scheduler | - | DAGスケジューリング |
| Airflow Worker | - | タスク実行 |
| Flower | 5555 | Celeryワーカー監視UI |

## 📋 前提条件

**以下のノードが起動していること:**
- Storage Node（PostgreSQL, Redis）
- DWH Node（ClickHouse）※dbt実行時に必要

## 🚀 セットアップ

```bash
# 1. 実行権限を付与
chmod +x setup.sh

# 2. Dockerの確認
./setup.sh check

# 3. ディレクトリ・権限設定
./setup.sh init

# 4. 設定ファイル生成（Storage/DWH Node IPを入力）
./setup.sh configure

# 5. サービスを起動
./setup.sh start
```

## 📋 コマンド一覧

```bash
./setup.sh check      # Dockerの確認
./setup.sh init       # ディレクトリ・権限設定
./setup.sh configure  # 設定ファイル生成
./setup.sh start      # サービスを起動
./setup.sh stop       # サービスを停止
./setup.sh restart    # サービスを再起動
./setup.sh status     # ステータス表示
./setup.sh logs       # 全ログ表示
./setup.sh logs airflow-webserver  # Webserverログ
./setup.sh reset      # 全データ削除
```

## 🔐 デフォルト認証情報

### Airflow
- **URL**: http://<このVMのIP>:8080
- **User**: admin
- **Password**: admin123

### Flower
- **URL**: http://<このVMのIP>:5555
- 認証なし

## 📁 ディレクトリ構成

```
etl-node/
├── docker-compose.yml
├── .env
├── setup.sh
├── README.md
├── dags/                    # AirflowのDAGファイル
│   └── sample_etl_pipeline.py
├── logs/                    # Airflowログ
├── plugins/                 # Airflowプラグイン
├── config/                  # Airflow設定
└── dbt/                     # dbtプロジェクト
    ├── profiles.yml.template
    ├── dbt_project.yml
    └── models/
        ├── bronze/
        ├── silver/
        ├── gold/
        └── marts/
```

## 📊 dbt使用方法

```bash
# Airflowコンテナ内でdbtコマンドを実行
docker exec -it airflow-worker bash

# dbt実行
cd /opt/airflow/dbt
dbt run --profiles-dir .
dbt test --profiles-dir .
```

## 🔗 Airflow接続設定

起動時に以下の接続が自動設定されます：

| Connection ID | 接続先 |
|--------------|--------|
| minio | Storage Node MinIO |
| clickhouse | DWH Node ClickHouse |
| postgres | Storage Node PostgreSQL |

## ⚙️ .env設定

```bash
# Airflow設定
AIRFLOW_UID=50000
AIRFLOW_USER=admin
AIRFLOW_PASSWORD=admin123

# 追加Pythonパッケージ
_PIP_ADDITIONAL_REQUIREMENTS=apache-airflow-providers-amazon ...

# 接続設定（必須）
STORAGE_NODE_IP=10.10.10.10
DWH_NODE_IP=10.10.10.20
```

## ⚠️ 注意事項

1. Storage Nodeが先に起動している必要があります（PostgreSQL, Redis使用）
2. 初回起動時はDB初期化のため数分かかります
3. DAGファイルは`dags/`ディレクトリに配置してください
4. dbt実行にはDWH Nodeが必要です
