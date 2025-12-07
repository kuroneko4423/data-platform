"""
サンプルDAG: MinIOとPostgreSQLを使用したデータパイプライン
このDAGはデータ分析基盤の基本的な使い方を示します。
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import json
import boto3
from botocore.client import Config


# デフォルト引数
default_args = {
    'owner': 'data-platform',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}


def get_minio_client():
    """MinIO S3クライアントを取得"""
    return boto3.client(
        's3',
        endpoint_url='http://minio:9000',
        aws_access_key_id='minioadmin',
        aws_secret_access_key='minioadmin',
        config=Config(signature_version='s3v4'),
        region_name='us-east-1'
    )


def extract_sample_data(**context):
    """サンプルデータを生成してMinIOに保存"""
    import json
    from datetime import datetime
    
    # サンプルデータ生成
    sample_data = [
        {"id": i, "value": i * 10, "timestamp": datetime.now().isoformat()}
        for i in range(1, 11)
    ]
    
    # MinIOに保存
    s3_client = get_minio_client()
    
    file_key = f"sample_data_{context['ds']}.json"
    s3_client.put_object(
        Bucket='raw-data',
        Key=file_key,
        Body=json.dumps(sample_data),
        ContentType='application/json'
    )
    
    print(f"Data saved to MinIO: raw-data/{file_key}")
    return file_key


def transform_and_load(**context):
    """MinIOからデータを読み取り、変換してPostgreSQLに保存"""
    import json
    
    ti = context['ti']
    file_key = ti.xcom_pull(task_ids='extract_data')
    
    # MinIOからデータ読み取り
    s3_client = get_minio_client()
    response = s3_client.get_object(Bucket='raw-data', Key=file_key)
    data = json.loads(response['Body'].read().decode('utf-8'))
    
    # PostgreSQLに保存
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    for record in data:
        pg_hook.run(
            """
            INSERT INTO raw.sample_data (data, created_at)
            VALUES (%s, CURRENT_TIMESTAMP)
            """,
            parameters=(json.dumps(record),)
        )
    
    print(f"Loaded {len(data)} records to PostgreSQL")
    
    # 処理済みデータをMinIOに保存
    processed_key = f"processed_{file_key}"
    s3_client.put_object(
        Bucket='processed-data',
        Key=processed_key,
        Body=json.dumps({"status": "processed", "records": len(data)}),
        ContentType='application/json'
    )
    
    return len(data)


def aggregate_data(**context):
    """データを集計してmartスキーマに保存"""
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # 集計クエリ実行
    pg_hook.run(
        """
        INSERT INTO mart.aggregated_data (metric_name, metric_value, aggregated_at)
        SELECT 
            'total_records',
            COUNT(*),
            CURRENT_TIMESTAMP
        FROM raw.sample_data
        WHERE created_at >= CURRENT_DATE
        """
    )
    
    print("Aggregation completed")


# DAG定義
with DAG(
    'sample_etl_pipeline',
    default_args=default_args,
    description='MinIOとPostgreSQLを使用したサンプルETLパイプライン',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['sample', 'etl', 'minio', 'postgres'],
) as dag:

    # タスク1: データ抽出
    extract_task = PythonOperator(
        task_id='extract_data',
        python_callable=extract_sample_data,
    )

    # タスク2: データ変換・ロード
    transform_load_task = PythonOperator(
        task_id='transform_and_load',
        python_callable=transform_and_load,
    )

    # タスク3: データ集計
    aggregate_task = PythonOperator(
        task_id='aggregate_data',
        python_callable=aggregate_data,
    )

    # タスク依存関係
    extract_task >> transform_load_task >> aggregate_task
