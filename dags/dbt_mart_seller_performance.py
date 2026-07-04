from datetime import datetime

from airflow import DAG

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig 
from cosmos.constants import ExecutionMode


with DAG(
    dag_id="dbt_mart_seller_performance",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:

    dbt_run = DbtTaskGroup(
        group_id="dbt_run",

        project_config=ProjectConfig(
            dbt_project_path="/home/de24/dbt_projects/e_commerce",
        ),

        profile_config=ProfileConfig(
            profile_name="e_commerce",
            target_name="dev",
            profiles_yml_filepath="/home/de24/.dbt/profiles.yml",
        ),

        execution_config=ExecutionConfig(
            execution_mode=ExecutionMode.LOCAL,
        ),

        render_config=RenderConfig(
            select=["+mart_seller_performance"], # dbt run --select  mart_seller_performance
        ),
        # operator_args={       this runs all the model need to understand the why this happens
        #     "select": ["brz_customers"],
        # }
    )