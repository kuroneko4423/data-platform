-- =============================================================================
-- Bronze層: 生データ取り込みサンプル
-- PostgreSQL DWH用
-- =============================================================================

{{
    config(
        materialized='table',
        schema='bronze'
    )
}}

SELECT
    gen_random_uuid() as id,
    NOW() as loaded_at,
    'sample_source' as source_system,
    'placeholder' as raw_data
