#!/bin/bash

# =============================================================================
# ETL Node セットアップスクリプト
# Ubuntu Desktop 24.04用
# =============================================================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_title() { echo -e "${BLUE}[====]${NC} $1"; }

# 設定ファイル読み込み
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# -----------------------------------------------------------------------------
# Dockerインストール確認
# -----------------------------------------------------------------------------
check_docker() {
    log_title "Dockerの確認"
    
    if ! command -v docker &> /dev/null; then
        log_warn "Dockerがインストールされていません。インストールします..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log_warn "Dockerをインストールしました。一度ログアウトして再ログインしてください。"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        log_warn "Docker Compose V2をインストールします..."
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
    fi
    
    log_info "Docker: $(docker --version)"
    log_info "Docker Compose: $(docker compose version)"
}

# -----------------------------------------------------------------------------
# ディレクトリ・権限設定
# -----------------------------------------------------------------------------
init() {
    log_title "ディレクトリと権限を設定します"
    
    # ディレクトリ作成
    mkdir -p dags logs plugins config
    mkdir -p dbt/models/{bronze,silver,gold,marts}
    mkdir -p dbt/seeds dbt/tests dbt/macros dbt/snapshots dbt/analyses
    
    # Airflow用の権限設定（UID=50000）
    sudo chown -R 50000:0 dags logs plugins 2>/dev/null || true
    chmod -R 775 dags logs plugins 2>/dev/null || true
    
    log_info "ディレクトリ作成完了"
}

# -----------------------------------------------------------------------------
# 設定ファイル生成
# -----------------------------------------------------------------------------
configure() {
    log_title "設定ファイルを生成します"
    
    # Storage Node IPの確認
    if [ -z "$STORAGE_NODE_IP" ]; then
        echo ""
        read -p "Storage NodeのIPアドレスを入力してください: " STORAGE_NODE_IP
    fi
    
    # DWH Node IPの確認
    if [ -z "$DWH_NODE_IP" ]; then
        read -p "DWH NodeのIPアドレスを入力してください: " DWH_NODE_IP
    fi
    
    # .envを更新
    cat > .env << EOF
# ETL Node 環境変数
AIRFLOW_UID=50000
AIRFLOW_USER=admin
AIRFLOW_PASSWORD=admin123

_PIP_ADDITIONAL_REQUIREMENTS=apache-airflow-providers-amazon apache-airflow-providers-postgres dbt-core dbt-clickhouse dbt-postgres boto3 clickhouse-driver pandas pyarrow

# 接続設定
STORAGE_NODE_IP=$STORAGE_NODE_IP
DWH_NODE_IP=$DWH_NODE_IP
EOF
    
    log_info "Storage Node IP: $STORAGE_NODE_IP"
    log_info "DWH Node IP: $DWH_NODE_IP"
    
    # dbt profiles.ymlを生成
    if [ -f dbt/profiles.yml.template ]; then
        sed -e "s/STORAGE_NODE_IP/$STORAGE_NODE_IP/g" \
            -e "s/DWH_NODE_IP/$DWH_NODE_IP/g" \
            dbt/profiles.yml.template > dbt/profiles.yml
        log_info "dbt/profiles.yml を生成しました"
    fi
    
    log_info "設定ファイル生成完了"
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------
show_info() {
    echo ""
    echo "=========================================="
    echo "  ETL Node"
    echo "  Services: Apache Airflow, dbt"
    echo "=========================================="
    echo ""
    echo "提供サービス:"
    echo "  - Airflow Webserver : ポート 8080"
    echo "  - Flower (監視UI)   : ポート 5555"
    echo ""
}

start() {
    log_title "ETL Nodeを起動します"
    
    # 設定確認
    if [ ! -f dbt/profiles.yml ]; then
        log_warn "設定ファイルが生成されていません。"
        configure
    fi
    
    docker compose up -d
    
    echo ""
    log_info "起動完了！（初回は数分かかる場合があります）"
    echo ""
    echo "アクセス情報:"
    echo "  Airflow: http://$(hostname -I | awk '{print $1}'):8080"
    echo "    User: admin"
    echo "    Password: admin123"
    echo ""
    echo "  Flower: http://$(hostname -I | awk '{print $1}'):5555"
    echo ""
    echo "このVMのIPアドレスを他のノードの.envファイルに設定してください:"
    echo "  ETL_NODE_IP=$(hostname -I | awk '{print $1}')"
    echo ""
}

stop() {
    log_title "ETL Nodeを停止します"
    docker compose down
    log_info "停止完了"
}

status() {
    log_title "コンテナステータス"
    docker compose ps
}

logs() {
    local service="${1:-}"
    if [ -z "$service" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$service"
    fi
}

reset() {
    log_warn "全データを削除します。よろしいですか？ (y/N)"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        docker compose down -v
        log_info "データを削除しました"
    else
        log_info "キャンセルしました"
    fi
}

case "${1:-}" in
    "check")
        check_docker
        ;;
    "init")
        init
        ;;
    "configure")
        configure
        ;;
    "start")
        check_docker
        init
        start
        ;;
    "stop")
        stop
        ;;
    "restart")
        stop
        start
        ;;
    "status")
        status
        ;;
    "logs")
        logs "$2"
        ;;
    "reset")
        reset
        ;;
    "info")
        show_info
        ;;
    *)
        show_info
        echo "使用方法: $0 <command>"
        echo ""
        echo "コマンド:"
        echo "  check      Dockerの確認・インストール"
        echo "  init       ディレクトリ・権限設定"
        echo "  configure  設定ファイル生成（Storage/DWH Node IPを設定）"
        echo "  start      サービスを起動"
        echo "  stop       サービスを停止"
        echo "  restart    サービスを再起動"
        echo "  status     ステータス表示"
        echo "  logs       ログ表示 (例: $0 logs airflow-webserver)"
        echo "  reset      全データ削除"
        echo "  info       ノード情報表示"
        echo ""
        ;;
esac
