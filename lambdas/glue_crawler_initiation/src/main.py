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

        crawler = request_state.get("Crawler")
        state = crawler.get("State")

        if state == "READY":
            last_crawl = crawler.get("LastCrawl")
            last_crawl_state = last_crawl.get("Status")

            if last_crawl_state in ["FAILED", "CANCELLED"]:
                raise Exception(f"{last_crawl.get('ErrorMessage')}")
            elif last_crawl_state == "SUCCEEDED":
                logger.info(f"Crawler {crawler_name} run success.")
                return last_crawl_state
        else:
            logger.info(f"Crawler {crawler_name} still in ${state} state.")

            time.sleep(20)
            return check_state(client, crawler_name)

    except Exception as err:
        logger.error(f"Get crawler {crawler_name} state failed: ${str(err)}")
        raise err


def get_crawler_name(args: Tuple[Any, ...]) -> str:

    try:
        crawler_name = args[0]["CRAWLER_NAME"]
    except KeyError as kerr:
        logger.error(f"Unable to find crawler name from ${str(args)}")
        raise kerr

    return crawler_name


def handler(*args, **kwargs) -> str:

    client = boto3.client("glue")
    crawler_name = get_crawler_name(args)

    try:
        client.start_crawler(Name=crawler_name)

    except client.exceptions.CrawlerRunningException:
        logger.info(f"Crawler {crawler_name} is already running.")
    except Exception as e:
        logger.error(f"Crawler {crawler_name} Error: ${str(e)}")
        raise Exception(f"Crawler {crawler_name} Error: ${str(e)}")

    state = check_state(client, crawler_name)

    return state
