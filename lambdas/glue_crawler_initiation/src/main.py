import boto3
import logging
import os
import time
from typing import *

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def check_state(client: boto3.resource, crawler_name: str) -> str:

    try:

        request_state = client.get_crawler(Name=crawler_name)

        state = request_state.get("Crawler").get("State")
        last_crawler_state = request_state.get("Crawler").get("LastCrawl").get("Status")

        if state == "READY" and last_crawler_state in ["FAILED", "CANCELLED"]:
            raise Exception(
                f"{request_state.get('Crawler').get('LastCrawl').get('ErrorMessage')}"
            )
        elif state == "READY" and last_crawler_state == "SUCCEEDED":
            logger.info(f"Crawler ${crawler_name} run success.")
            return last_crawler_state
        else:
            logger.info(f"Crawler ${crawler_name} still in ${state} state.")

            time.sleep(int(os.getenv("CRAWLER_WAIT_TIME", 60)))
            return check_state(client, crawler_name)

    except Exception as e:
        logger.error(f"Get crawler ${crawler_name} state failed: ${str(e)}")
        raise Exception(f"Get crawler ${crawler_name} state failed: ${str(e)}")


def get_crawler_name(args: Tuple[Any, ...]) -> str:

    try:
        crawler_name = args[0]["CRAWLER_NAME"]
    except KeyError as kerr:
        logger.info(f"Unable to find crawler name from ${str(args)}")
        raise Exception(
            f"Key Error ${kerr}: Unable to find crawler name from ${str(args)}"
        )

    return crawler_name


def handler(*args, **kwargs) -> str:

    client = boto3.client("glue")

    try:
        crawler_name = get_crawler_name(args)
        client.start_crawler(Name=crawler_name)

    except client.exceptions.CrawlerRunningException:
        logger.info(f"Crawler ${crawler_name} is already running.")
    except Exception as e:
        logger.error(f"Crawler ${crawler_name} Error: ${str(e)}")
        raise Exception(f"Crawler ${crawler_name} Error: ${str(e)}")

    state = check_state(client, crawler_name)

    return state
