#!/bin/bash

# =============================================================================
# DWH Node セットアップスクリプト
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
# 設定ファイル生成
# -----------------------------------------------------------------------------
configure() {
    log_title "設定ファイルを生成します"
    
    # Storage Node IPの確認
    if [ -z "$STORAGE_NODE_IP" ]; then
        echo ""
        read -p "Storage NodeのIPアドレスを入力してください: " STORAGE_NODE_IP
        echo "STORAGE_NODE_IP=$STORAGE_NODE_IP" >> .env
    fi
    
    log_info "Storage Node IP: $STORAGE_NODE_IP"
    
    # MinIOカタログ設定を生成
    if [ -f trino/etc/catalog/minio.properties.template ]; then
        sed "s/STORAGE_NODE_IP/$STORAGE_NODE_IP/g" \
            trino/etc/catalog/minio.properties.template > \
            trino/etc/catalog/minio.properties
        log_info "trino/etc/catalog/minio.properties を生成しました"
    fi
    
    # PostgreSQLカタログ設定を生成
    if [ -f trino/etc/catalog/postgresql.properties.template ]; then
        sed "s/STORAGE_NODE_IP/$STORAGE_NODE_IP/g" \
            trino/etc/catalog/postgresql.properties.template > \
            trino/etc/catalog/postgresql.properties
        log_info "trino/etc/catalog/postgresql.properties を生成しました"
    fi
    
    log_info "設定ファイル生成完了"
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------
show_info() {
    echo ""
    echo "=========================================="
    echo "  DWH Node"
    echo "  Services: ClickHouse, Trino"
    echo "=========================================="
    echo ""
    echo "提供サービス:"
    echo "  - ClickHouse (OLAP DB)  : ポート 8123 (HTTP), 9000 (Native)"
    echo "  - Trino (クエリエンジン) : ポート 8080"
    echo ""
}

start() {
    log_title "DWH Nodeを起動します"
    
    # 設定ファイルの確認
    if [ ! -f trino/etc/catalog/minio.properties ]; then
        log_warn "設定ファイルが生成されていません。先に configure を実行してください。"
        configure
    fi
    
    docker compose up -d
    
    echo ""
    log_info "起動完了！"
    echo ""
    echo "アクセス情報:"
    echo "  ClickHouse HTTP: http://$(hostname -I | awk '{print $1}'):8123"
    echo "    User: default / Password: clickhouse123"
    echo ""
    echo "  Trino: http://$(hostname -I | awk '{print $1}'):8080"
    echo ""
    echo "このVMのIPアドレスを他のノードの.envファイルに設定してください:"
    echo "  DWH_NODE_IP=$(hostname -I | awk '{print $1}')"
    echo ""
}

stop() {
    log_title "DWH Nodeを停止します"
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
    "configure")
        configure
        ;;
    "start")
        check_docker
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
        echo "  configure  設定ファイル生成（Storage Node IPを設定）"
        echo "  start      サービスを起動"
        echo "  stop       サービスを停止"
        echo "  restart    サービスを再起動"
        echo "  status     ステータス表示"
        echo "  logs       ログ表示 (例: $0 logs clickhouse)"
        echo "  reset      全データ削除"
        echo "  info       ノード情報表示"
        echo ""
        ;;
esac
