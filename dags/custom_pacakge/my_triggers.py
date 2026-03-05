# Custom Trigger that simply sleeps for X seconds, then fires an event

from airflow.triggers.base import BaseTrigger, TriggerEvent
import asyncio

class SleepTrigger(BaseTrigger):
    def __init__(self, sleep_time: int):
        super().__init__()
        self.sleep_time = sleep_time

    def serialize(self):
        return ("my_operators.SleepTrigger", {"sleep_time": self.sleep_time})

    async def run(self):
        await asyncio.sleep(self.sleep_time)
        yield TriggerEvent({"status": "awake"})
