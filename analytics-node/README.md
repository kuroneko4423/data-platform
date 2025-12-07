# 📊 Analytics Node

BI・可視化機能を提供するノードです。

## 🏗️ 構成サービス

| サービス | ポート | 用途 |
|---------|--------|------|
| Apache Superset | 8088 | エンタープライズBI |
| Metabase | 3000 | セルフサービスBI |

## 📋 前提条件

**以下のノードが起動していること:**
- Storage Node（PostgreSQL, Redis）

## 🚀 セットアップ

```bash
# 1. 実行権限を付与
chmod +x setup.sh

# 2. Dockerの確認
./setup.sh check

# 3. 設定ファイル生成（Storage/DWH Node IPを入力）
./setup.sh configure

# 4. サービスを起動
./setup.sh start
```

## 📋 コマンド一覧

```bash
./setup.sh check      # Dockerの確認
./setup.sh configure  # 設定ファイル生成
./setup.sh start      # サービスを起動
./setup.sh stop       # サービスを停止
./setup.sh restart    # サービスを再起動
./setup.sh status     # ステータス表示
./setup.sh logs       # 全ログ表示
./setup.sh logs superset   # Supersetログ
./setup.sh logs metabase   # Metabaseログ
./setup.sh reset      # 全データ削除
```

## 🔐 デフォルト認証情報

### Superset
- **URL**: http://<このVMのIP>:8088
- **User**: admin
- **Password**: admin123

### Metabase
- **URL**: http://<このVMのIP>:3000
- 初回アクセス時にセットアップ画面が表示されます

## 🔗 データソース接続設定

### Supersetでの接続追加

1. Settings → Database Connections
2. + Database をクリック

**ClickHouse接続:**
```
clickhouse+native://default:clickhouse123@<DWH_NODE_IP>:9000/default
```

**PostgreSQL接続:**
```
postgresql://analyst:analyst123@<STORAGE_NODE_IP>:5432/analytics
```

### Metabaseでの接続追加

1. 設定（歯車アイコン）→ 管理者 → データベース
2. データベースを追加

**ClickHouse:**
- データベースタイプ: ClickHouse
- ホスト: <DWH_NODE_IP>
- ポート: 8123
- ユーザー: default
- パスワード: clickhouse123

## 📁 ファイル構成

```
analytics-node/
├── docker-compose.yml
├── .env
├── setup.sh
├── README.md
└── superset/
    └── superset_config.py
```

## ⚙️ .env設定

```bash
# Superset設定
SUPERSET_SECRET_KEY=your-secret-key-change-in-production-12345
SUPERSET_USER=admin
SUPERSET_PASSWORD=admin123

# 接続設定（必須）
STORAGE_NODE_IP=10.10.10.10
DWH_NODE_IP=10.10.10.20
```

## ⚠️ 注意事項

1. Storage Nodeが先に起動している必要があります
2. 初回起動時はDB初期化のため数分かかります
3. 本番環境では`SUPERSET_SECRET_KEY`を必ず変更してください
