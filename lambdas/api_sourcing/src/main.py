import boto3
import logging
from typing import *
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import json
import io

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


def handler(*args, **kwargs) -> Dict[str, Union[str, int]]:
    is_complete = False
    handler_input = get_handler_input(args)

    page_number = handler_input.get("PAGE_NUMBER", 0)
    endpoint = build_endpoint(
        handler_input.get("URL"),
        handler_input.get("PAGESIZE"),
        page_number,
        handler_input.get("APIKEY"),
    )

    page_data = marshall_page(handler_input.get("DATA_KEY"), get_page(endpoint))

    if len(page_data) == 0:
        is_complete = True
        logger.info("Completed")

    else:
        upload_fileobj(
            io.BytesIO(rebuild_multiline_json(page_data)),
            handler_input.get("LANDING_BUCKET"),
            s3_key=f"{handler_input.get('TABLE_NAME')}/{page_number}.json",
        )
        logger.info(f"Completed page {endpoint}")

    handler_input["IS_COMPLETE"] = is_complete
    handler_input["PAGE_NUMBER"] = page_number + 1

    return handler_input


def build_endpoint(
        url: str,
        pagesize: Optional[int] = None,
        page: Optional[int] = None,
        api_key: Optional[str] = None
) -> str:

    return (f"https://{url}"
            + (f"&pageSize={pagesize}" if pagesize is not None else "")
            + (f"&page={page}" if page is not None else "")
            + (f"&apiKey={api_key}" if api_key is not None else ""))


def get_page(endpoint: str) -> Dict[str, Any]:
    logger.info(f"ENDPOINT: {endpoint}")

    try:
        return json.loads(urlopen(Request(endpoint)).read().decode("utf-8"))

    except HTTPError as errh:
        logger.error("Http Error:: %s" % errh)
        raise errh
    except Exception as err:
        logger.error("Something Else Error:: %s" % err)
        raise err


def marshall_page(data_key: str, data: Dict[str, Any]) -> List[Optional[Dict]]:
    return data.get(data_key)


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
