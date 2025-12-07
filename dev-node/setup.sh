#!/bin/bash

# =============================================================================
# Dev Node セットアップスクリプト
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
# ディレクトリ作成
# -----------------------------------------------------------------------------
init() {
    log_title "ディレクトリを作成します"
    mkdir -p notebooks jupyter streamlit streamlit-apps workspace
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
# Dev Node 環境変数
JUPYTER_TOKEN=jupyter123
CODE_SERVER_PASSWORD=code123
SUDO_PASSWORD=sudo123

# 接続設定
STORAGE_NODE_IP=$STORAGE_NODE_IP
DWH_NODE_IP=$DWH_NODE_IP
EOF
    
    log_info "Storage Node IP: $STORAGE_NODE_IP"
    log_info "DWH Node IP: $DWH_NODE_IP"
    log_info "設定ファイル生成完了"
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------
show_info() {
    echo ""
    echo "=========================================="
    echo "  Dev Node"
    echo "  Services: JupyterLab, Code Server,"
    echo "            CloudBeaver, Streamlit"
    echo "=========================================="
    echo ""
    echo "提供サービス:"
    echo "  - JupyterLab   : ポート 8888"
    echo "  - Code Server  : ポート 8443"
    echo "  - CloudBeaver  : ポート 8978"
    echo "  - Streamlit    : ポート 8501"
    echo ""
}

start() {
    log_title "Dev Nodeを起動します"
    
    # 設定確認
    if [ -z "$STORAGE_NODE_IP" ]; then
        log_warn "Storage Node IPが設定されていません。"
        configure
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    docker compose up -d
    
    echo ""
    log_info "起動完了！"
    echo ""
    echo "アクセス情報:"
    echo "  JupyterLab: http://$(hostname -I | awk '{print $1}'):8888"
    echo "    Token: jupyter123"
    echo ""
    echo "  Code Server: http://$(hostname -I | awk '{print $1}'):8443"
    echo "    Password: code123"
    echo ""
    echo "  CloudBeaver: http://$(hostname -I | awk '{print $1}'):8978"
    echo "    初回アクセス時にセットアップ"
    echo ""
    echo "  Streamlit: http://$(hostname -I | awk '{print $1}'):8501"
    echo ""
}

stop() {
    log_title "Dev Nodeを停止します"
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
        echo "  init       ディレクトリ作成"
        echo "  configure  設定ファイル生成（Storage/DWH Node IPを設定）"
        echo "  start      サービスを起動"
        echo "  stop       サービスを停止"
        echo "  restart    サービスを再起動"
        echo "  status     ステータス表示"
        echo "  logs       ログ表示 (例: $0 logs jupyterlab)"
        echo "  reset      全データ削除"
        echo "  info       ノード情報表示"
        echo ""
        ;;
esac
