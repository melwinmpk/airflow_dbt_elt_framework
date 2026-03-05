from airflow.models import BaseOperator
from airflow.triggers.base import TriggerEvent
from airflow.utils.context import Context
from datetime import datetime, timedelta

from airflow.exceptions import AirflowFailException
from custom_pacakge.my_triggers import SleepTrigger
# from my_triggers import SleepTrigger

# import boto3

# def check_my_condition():
#     emr = boto3.client("emr")
#     cluster_id = "j-XXXXXXXX"
#     step_id = "s-YYYYYYYY"

#     step = emr.describe_step(ClusterId=cluster_id, StepId=step_id)
#     status = step["Step"]["Status"]["State"]
#     print(f"🔍 EMR step state: {status}")
#     return status in ("COMPLETED",)


# Replace with any logic you want 
def check_my_condition():
    import random
    print(f"<<========= condition checked =======>> ")
    return False #random.choice([True, False])


class MyDeferrableConditionOperator(BaseOperator):
    def __init__(self, sleep_time=15, max_wait_time=120, **kwargs):
        super().__init__(**kwargs)
        self.sleep_time = sleep_time
        self.max_wait_time = max_wait_time

    def execute(self, context: Context):
        ti = context["ti"]

        # Get or set the start time
        start_time_str = ti.xcom_pull(task_ids=self.task_id, key="start_time")
        if start_time_str is None:
            start_time = datetime.utcnow()
            ti.xcom_push(key="start_time", value=start_time.isoformat())
            self.log.info("Start time set => %s", start_time)
        else:
            start_time = datetime.fromisoformat(start_time_str)

        # Check condition
        self.log.info("<<========= condition checked =======>>")
        if check_my_condition():
            self.log.info("Condition met - finishing task.")
            return "success"

        # Timeout check
        elapsed = (datetime.utcnow() - start_time).total_seconds()
        self.log.info("elapsed => %s", elapsed)
        if elapsed >= self.max_wait_time:
            self.log.error("Condition not met after %s seconds. Failing.", elapsed)
            raise AirflowFailException("Condition timed out")

        # Otherwise, defer
        self.log.info("Condition false, deferring for %s seconds", self.sleep_time)
        self.defer(trigger=SleepTrigger(self.sleep_time), method_name="execute_complete")

    def execute_complete(self, context: Context, event: TriggerEvent):
        # This is called after the trigger wakes up — just run execute() again
        return self.execute(context)