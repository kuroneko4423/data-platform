# =============================================================================
# Superset Configuration
# =============================================================================

import os
from celery.schedules import crontab

# -----------------------------------------------------------------------------
# 基本設定
# -----------------------------------------------------------------------------
ROW_LIMIT = 5000
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'your-secret-key-change-in-production')

# -----------------------------------------------------------------------------
# データベース接続
# -----------------------------------------------------------------------------
SQLALCHEMY_DATABASE_URI = (
    f"postgresql://{os.environ.get('DATABASE_USER', 'superset')}:"
    f"{os.environ.get('DATABASE_PASSWORD', 'superset123')}@"
    f"{os.environ.get('DATABASE_HOST', 'localhost')}:"
    f"{os.environ.get('DATABASE_PORT', '5432')}/"
    f"{os.environ.get('DATABASE_DB', 'superset')}"
)

# -----------------------------------------------------------------------------
# Redis/キャッシュ設定
# -----------------------------------------------------------------------------
REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')
REDIS_PASSWORD = os.environ.get('REDIS_PASSWORD', 'redis123')
REDIS_URL = f"redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"

CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_URL': REDIS_URL,
}

DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_data_',
    'CACHE_REDIS_URL': REDIS_URL,
}

# -----------------------------------------------------------------------------
# Celery設定
# -----------------------------------------------------------------------------
class CeleryConfig:
    broker_url = REDIS_URL
    result_backend = REDIS_URL
    imports = ('superset.sql_lab', 'superset.tasks.scheduler')

CELERY_CONFIG = CeleryConfig

# -----------------------------------------------------------------------------
# SQL Lab設定
# -----------------------------------------------------------------------------
SQLLAB_TIMEOUT = 300
SQLLAB_ASYNC_TIME_LIMIT_SEC = 600
SQL_MAX_ROW = 100000

# -----------------------------------------------------------------------------
# 機能フラグ
# -----------------------------------------------------------------------------
FEATURE_FLAGS = {
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DASHBOARD_NATIVE_FILTERS': True,
    'DASHBOARD_CROSS_FILTERS': True,
    'ALERT_REPORTS': True,
}

# -----------------------------------------------------------------------------
# 言語設定
# -----------------------------------------------------------------------------
BABEL_DEFAULT_LOCALE = 'ja'
LANGUAGES = {
    'en': {'flag': 'us', 'name': 'English'},
    'ja': {'flag': 'jp', 'name': 'Japanese'},
}
