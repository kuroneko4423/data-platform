# 💻 Dev Node

開発・分析環境を提供するノードです。

## 🏗️ 構成サービス

| サービス | ポート | 用途 |
|---------|--------|------|
| JupyterLab | 8888 | インタラクティブ分析 |
| Code Server | 8443 | Web版VS Code |
| CloudBeaver | 8978 | Web版DBクライアント |
| Streamlit | 8501 | データアプリ |

## 📋 前提条件

**以下のノードが起動していること（推奨）:**
- Storage Node（MinIO, PostgreSQL）
- DWH Node（ClickHouse）

※他ノードなしでも起動可能ですが、接続機能は使用できません。

## 🚀 セットアップ

```bash
# 1. 実行権限を付与
chmod +x setup.sh

# 2. Dockerの確認
./setup.sh check

# 3. ディレクトリ作成
./setup.sh init

# 4. 設定ファイル生成（Storage/DWH Node IPを入力）
./setup.sh configure

# 5. サービスを起動
./setup.sh start
```

## 📋 コマンド一覧

```bash
./setup.sh check      # Dockerの確認
./setup.sh init       # ディレクトリ作成
./setup.sh configure  # 設定ファイル生成
./setup.sh start      # サービスを起動
./setup.sh stop       # サービスを停止
./setup.sh restart    # サービスを再起動
./setup.sh status     # ステータス表示
./setup.sh logs       # 全ログ表示
./setup.sh logs jupyterlab  # JupyterLabログ
./setup.sh reset      # 全データ削除
```

## 🔐 デフォルト認証情報

### JupyterLab
- **URL**: http://<このVMのIP>:8888
- **Token**: jupyter123

### Code Server
- **URL**: http://<このVMのIP>:8443
- **Password**: code123

### CloudBeaver
- **URL**: http://<このVMのIP>:8978
- 初回アクセス時にセットアップ

### Streamlit
- **URL**: http://<このVMのIP>:8501
- 認証なし

## 📁 ファイル構成

```
dev-node/
├── docker-compose.yml
├── .env
├── setup.sh
├── README.md
├── jupyter/
│   └── requirements.txt
├── notebooks/
│   └── 01_quickstart.ipynb
├── streamlit/
│   └── requirements.txt
├── streamlit-apps/
│   └── app.py
└── workspace/            # Code Server用
```

## 🔗 JupyterLabでの接続例

```python
import os

STORAGE_NODE = os.environ.get('STORAGE_NODE_IP')
DWH_NODE = os.environ.get('DWH_NODE_IP')

# ClickHouse接続
import clickhouse_connect
ch = clickhouse_connect.get_client(
    host=DWH_NODE, port=8123,
    username='default', password='clickhouse123'
)

# MinIO接続
import boto3
s3 = boto3.client('s3',
    endpoint_url=f'http://{STORAGE_NODE}:9000',
    aws_access_key_id='minioadmin',
    aws_secret_access_key='minioadmin123'
)
```

## ⚙️ .env設定

```bash
# JupyterLab設定
JUPYTER_TOKEN=jupyter123

# Code Server設定
CODE_SERVER_PASSWORD=code123

# 接続設定
STORAGE_NODE_IP=10.10.10.10
DWH_NODE_IP=10.10.10.20
```

## 📚 インストール済みライブラリ（JupyterLab）

- clickhouse-connect, clickhouse-driver
- psycopg2-binary, sqlalchemy
- boto3, s3fs
- polars, duckdb, pyarrow
- plotly, altair
- その他（requirements.txt参照）

## ⚠️ 注意事項

1. 他ノードへの接続には事前にIPアドレスの設定が必要です
2. notebooks/ディレクトリにノートブックを保存してください
3. streamlit-apps/app.pyを編集してカスタムアプリを作成できます
