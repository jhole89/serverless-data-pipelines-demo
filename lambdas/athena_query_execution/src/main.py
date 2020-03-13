import boto3
import os
import logging
from typing import *
import time

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_handler_input_args(args: Tuple[Any, ...]) -> Tuple[Any, ...]:

    try:
        sql_query_files = args[0]["SQL_QUERY_FILES"]
        table_name = args[0]["TABLENAME"]
        athena_database = args[0]["ATHENA_DATABASE"]
        workgroup = args[0]["WORKGROUP"]

    except KeyError as kerr:
        logger.error("Unable to get args from lambda input: %s" % kerr)
        raise kerr
    except IndexError as inderr:
        logger.error("Unable to get args from lambda input %s: %s" % (str(args), inderr))
        raise inderr

    return sql_query_files, table_name, athena_database, workgroup


def check_state(athena: boto3.resource, query: str, exec_id: str) -> str:
    request_status = athena.get_query_execution(QueryExecutionId=exec_id)
    status = request_status.get("QueryExecution").get("Status")
    state = status.get("State")
    if state in ["FAILED", "CANCELLED"]:
        raise Exception(
            f"Query {query} failed with execution {exec_id}: {status.get('StateChangeReason')}"
        )
    elif state == "SUCCEEDED":
        logger.info(f"Query {query} succeeded with execution {exec_id}")
        return state
    else:
        logger.info(f"Query {query} running with execution {exec_id}")
        time.sleep(5)
        return check_state(athena, query, exec_id)


def handler(*args, **kwargs) -> List[str]:
    sql_query_files, table_name, athena_database, workgroup = get_handler_input_args(args)
    athena = boto3.client("athena")
    query_ids = []
    for query in sql_query_files.split(","):
        with open(
            os.path.join(os.path.abspath(os.path.dirname(__file__)), "sql", query),
            "r",
        ) as queryfile:
            try:
                response = athena.start_query_execution(
                    QueryString=queryfile.read().format("bestbuy_products", table_name),
                    QueryExecutionContext={"Database": athena_database},
                    WorkGroup=workgroup,
                )
                exec_id = response.get("QueryExecutionId")
                logger.info(f"Query {query} initiated with execution {exec_id}")
                check_state(athena, query, exec_id)
                query_ids.append(exec_id)
            except AttributeError:
                logger.error(f"Could not find query {query}")
    return query_ids
