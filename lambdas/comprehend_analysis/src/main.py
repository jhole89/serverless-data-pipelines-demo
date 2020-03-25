import boto3
import logging
from typing import *
import json
import io
import time
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_handler_input(args: Tuple[Any, ...]) -> Dict[str, Union[str, int]]:

    try:
        handler_input = args[0].get("input")

        if handler_input is None:
            logger.error(f"Unable to get input from handler: {args[0]}")
            raise KeyError

    except Exception as err:
        logger.error(f"Unable to get input from handler {str(args)}: {err}")
        raise err

    return handler_input


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
        time.sleep(20)
        return check_state(athena, query, exec_id)


def unpack_varchar_value(row: Dict[str, List[Dict[str, str]]]) -> Tuple[Optional[str]]:
    return tuple(data.get("VarCharValue") for data in row.get("Data"))


def comprehend_text(
        comprehend: boto3.resource,
        freetext: str,
        language: Optional[str] = "en"
) -> List[Dict[str, Optional[str]]]:

    entities = comprehend.detect_entities(Text=freetext, LanguageCode=language)
    return [
        {
            "Entity": entity.get("Text"),
            "Category": entity.get("Type"),
        } for entity in entities.get("Entities") if entity.get("Score") > 0.5
    ]


def construct_record(
        comprehend: boto3.resource,
        headers: Tuple[str],
        row: Dict[str, List[Dict[str, str]]]
) -> Dict[str, List[Dict[str, Optional[str]]]]:
    unpacked_data = unpack_varchar_value(row)
    return {
            **{header: unpacked for (header, unpacked) in zip(headers, unpacked_data)},
            "entities": comprehend_text(comprehend, unpacked_data[-1])
        }


def process_data(
        athena: boto3.resource,
        comprehend: boto3.resource,
        query_id: str,
        token: Optional[str] = None,
        data: List[Tuple[str]] = None,
        headers: Tuple[Optional[str]] = None
) -> List[Dict[str, Union[int, str, Dict[str, str]]]]:

    results = (
        athena.get_query_results(QueryExecutionId=query_id, MaxResults=1000, NextToken=token)
        if token
        else athena.get_query_results(QueryExecutionId=query_id, MaxResults=1000)
    )

    data = [] if data is None else data
    header_offset = 0
    rows = results.get("ResultSet").get("Rows")

    if headers is None:
        headers = unpack_varchar_value(rows[header_offset])
        header_offset += 1

    for row in rows[header_offset:]:
        data += [construct_record(comprehend, headers, row)]

    next_token = results.get("NextToken")
    if next_token:
        return process_data(athena, comprehend, query_id, token=next_token, data=data, headers=headers)
    else:
        return data


def handler(*args, **kwargs) -> None:
    handler_input = get_handler_input(args)
    athena = boto3.client("athena")
    comprehend = boto3.client("comprehend")
    query = handler_input.get("ANALYTICS_SQL_FILE")

    with open(
        os.path.join(os.path.abspath(os.path.dirname(__file__)), "sql", query), "r"
    ) as queryfile:

        response = athena.start_query_execution(
            QueryString=queryfile.read().format("sku", "name", handler_input.get("TABLENAME")),
            QueryExecutionContext={"Database": handler_input.get("ATHENA_DATABASE")},
            WorkGroup=handler_input.get("WORKGROUP"),
        )

    exec_id = response.get("QueryExecutionId")
    logger.info(f"Query {query} initiated with execution {exec_id}")
    state = check_state(athena, query, exec_id)

    data = process_data(athena, comprehend, exec_id) if state == "SUCCEEDED" else []

    upload_fileobj(
        io.BytesIO(rebuild_multiline_json(data)),
        handler_input.get("ANALYTICS_BUCKET"),
        s3_key=f"{handler_input.get('TABLENAME')}/comprehend.json",
    )


def upload_fileobj(file_bytes: io.BytesIO, s3_bucket: str, s3_key: str) -> None:
    if s3_key.startswith("/"):
        s3_key = s3_key.lstrip("/")
    s3_client = boto3.client("s3")
    logger.debug(f"File uploaded to [{s3_bucket}/{s3_key}]")
    s3_client.upload_fileobj(file_bytes, s3_bucket, s3_key)


def rebuild_multiline_json(response: List[Optional[Dict]]) -> bytes:
    multiline_json_list = [json.dumps(rec) for rec in response]
    multiline_content = "\n".join(multiline_json_list)
    return str.encode(multiline_content)
