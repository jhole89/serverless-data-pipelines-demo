import boto3
import os
import logging
from typing import *
import time

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_handler_input_args(args: Tuple[Any, ...]) -> Tuple[Any, ...]:

    try:
        url = args[0]["URL"]

    except KeyError as kerr:
        logger.error("Unable to get args from lambda input: %s" % kerr)
        raise KeyError("Unable to get args from lambda input: %s" % kerr)
    except IndexError as inderr:
        logger.error("Unable to get args from lambda input %s: %s" % (str(args), inderr))
        raise IndexError("Unable to get args from lambda input %s: %s" % (str(args), inderr))

    return url


def handler(*args, **kwargs) -> List[str]:
    url = get_handler_input_args(args)
    return url
