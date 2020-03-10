import boto3
import logging
from typing import *
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import json
import io

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_handler_arg(args: Tuple[Any, ...], key: str) -> Optional[Union[str, int]]:

    try:
        arg_value = args[0][key]

    except KeyError as kerr:
        logger.error(f"Unable to get {key} from lambda input: {kerr}")
        raise kerr
    except IndexError as inderr:
        logger.error(f"Unable to get {key} from lambda input {str(args)}: {inderr}")
        raise inderr

    return arg_value


def handler(*args, **kwargs) -> Dict[str, Union[str, int]]:
    is_complete = False
    page_number = get_handler_arg(args, "PAGE_NUMBER")
    endpoint = build_endpoint(get_handler_arg(args, "URL"), get_handler_arg(args, "APIKEY"))

    page_data = marshall_page(get_handler_arg(args, "DATA_KEY"), get_page(endpoint))

    if len(page_data) == 0:
        is_complete = True
        logger.info("Completed")

    else:
        upload_fileobj(
            io.BytesIO(rebuild_multiline_json(page_data)),
            get_handler_arg(args, "LANDING_BUCKET"),
            s3_key=f"{get_handler_arg(args, 'TABLE_NAME')}/{page_number}.json",
        )
        logger.info(f"Completed page {endpoint}")

    handler_input = {
        "is_complete": is_complete,
        "page_number": int(page_number) + 1,
    }

    return handler_input


def build_endpoint(
        url: str,
        pagesize: Optional[int] = None,
        page: Optional[int] = None,
        api_key: Optional[str] = None
) -> str:

    return (f"https://{url}"
            + (f"&pageSize={pagesize}" if page else "")
            + (f"&page={page}" if page else "")
            + (f"&apiKey={api_key}" if api_key else ""))


def get_page(endpoint: str) -> Dict[str, Any]:

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
