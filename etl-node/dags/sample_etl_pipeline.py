"""
=============================================================================
Sample ETL Pipeline DAG
=============================================================================
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator


default_args = {
    'owner': 'data-platform',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}


def extract_data(**context):
    """データ抽出処理"""
    print("Extracting data from source...")
    return {'status': 'extracted', 'records': 100}


def transform_data(**context):
    """データ変換処理"""
    ti = context['ti']
    extract_result = ti.xcom_pull(task_ids='extract')
    print(f"Transforming {extract_result['records']} records...")
    return {'status': 'transformed', 'records': extract_result['records']}


def load_data(**context):
    """データロード処理"""
    ti = context['ti']
    transform_result = ti.xcom_pull(task_ids='transform')
    print(f"Loading {transform_result['records']} records to DWH...")
    return {'status': 'loaded', 'records': transform_result['records']}


with DAG(
    dag_id='sample_etl_pipeline',
    default_args=default_args,
    description='Sample ETL Pipeline',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'sample'],
) as dag:

    extract = PythonOperator(
        task_id='extract',
        python_callable=extract_data,
    )

    transform = PythonOperator(
        task_id='transform',
        python_callable=transform_data,
    )

    load = PythonOperator(
        task_id='load',
        python_callable=load_data,
    )

    run_dbt = BashOperator(
        task_id='run_dbt',
        bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir /opt/airflow/dbt || true',
    )

    extract >> transform >> load >> run_dbt
