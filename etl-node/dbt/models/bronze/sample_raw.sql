-- =============================================================================
-- Bronze層: 生データ取り込みサンプル
-- =============================================================================

{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='id'
    )
}}

SELECT
    generateUUIDv4() as id,
    now() as loaded_at,
    'sample_source' as source_system,
    'placeholder' as raw_data
