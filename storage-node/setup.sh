#!/bin/bash

# =============================================================================
# Storage Node セットアップスクリプト
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
# メイン処理
# -----------------------------------------------------------------------------
show_info() {
    echo ""
    echo "=========================================="
    echo "  Storage Node"
    echo "  Services: MinIO, PostgreSQL, Redis"
    echo "=========================================="
    echo ""
    echo "提供サービス:"
    echo "  - MinIO (データレイク)    : ポート 9000 (API), 9001 (Console)"
    echo "  - PostgreSQL (メタデータDB): ポート 5432"
    echo "  - Redis (キャッシュ)       : ポート 6379"
    echo ""
}

start() {
    log_title "Storage Nodeを起動します"
    docker compose up -d
    
    echo ""
    log_info "起動完了！"
    echo ""
    echo "アクセス情報:"
    echo "  MinIO Console: http://$(hostname -I | awk '{print $1}'):9001"
    echo "    User: minioadmin"
    echo "    Password: minioadmin123"
    echo ""
    echo "  PostgreSQL: $(hostname -I | awk '{print $1}'):5432"
    echo "    User: postgres / Password: postgres123"
    echo ""
    echo "  Redis: $(hostname -I | awk '{print $1}'):6379"
    echo "    Password: redis123"
    echo ""
    echo "このVMのIPアドレスを他のノードの.envファイルに設定してください:"
    echo "  STORAGE_NODE_IP=$(hostname -I | awk '{print $1}')"
    echo ""
}

stop() {
    log_title "Storage Nodeを停止します"
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
        echo "  check    Dockerの確認・インストール"
        echo "  start    サービスを起動"
        echo "  stop     サービスを停止"
        echo "  restart  サービスを再起動"
        echo "  status   ステータス表示"
        echo "  logs     ログ表示 (例: $0 logs postgres)"
        echo "  reset    全データ削除"
        echo "  info     ノード情報表示"
        echo ""
        ;;
esac
