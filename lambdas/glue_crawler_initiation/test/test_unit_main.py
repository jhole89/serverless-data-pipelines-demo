import os
from typing import *
from unittest.mock import patch, Mock
import pytest

from glue_crawler_initiation.src.main import handler, check_state, get_crawler_name


def test_handler():
    mock_crawler = Mock()
    with patch("boto3.client", Mock(return_value=mock_crawler)):
        mock_crawler.start_crawler = Mock(
            return_value={
                "ResponseMetadata": {
                    "RequestId": "31cfb743-ffe9-11e9-82e6-dde5d132791c",
                    "HTTPStatusCode": 200,
                    "RetryAttempts": 0,
                }
            }
        )

        mock_crawler.get_crawler = Mock(
            return_value={
                "Crawler": {
                    "Name": "landing",
                    "State": "READY",
                    "LastCrawl": {
                        "Status": "SUCCEEDED",
                        "LogGroup": "/aws-glue/crawlers",
                        "LogStream": "LandingZoneCrawler",
                        "MessagePrefix": "b4f5294c-8196-4a2b-bfbf-74aa04dd8979",
                    },
                    "Version": 1,
                }
            }
        )

        run_crawler = handler(({"CRAWLER_NAME": "landing"}), None)
        assert run_crawler == "SUCCEEDED"


def return_crawler_respond_results(
    statue: str, last_statue: str, last_error: str = ""
) -> Dict[str, Any]:
    return {
        "Crawler": {
            "State": statue,
            "LastCrawl": {"Status": last_statue, "ErrorMessage": last_error},
        }
    }


@patch.dict(os.environ, {"CRAWLER_WAIT_TIME": "1"})
def test_check_state():
    mock_crawler = Mock()
    with patch("boto3.client", Mock(return_value=mock_crawler)):
        mock_crawler.get_crawler = Mock(
            side_effect=[
                return_crawler_respond_results("RUNNING", ""),
                return_crawler_respond_results("STOPPING", ""),
                return_crawler_respond_results("READY", "SUCCEEDED"),
            ]
        )
        state = check_state(mock_crawler, "landing")
        assert state == "SUCCEEDED"


@patch.dict(os.environ, {"CRAWLER_WAIT_TIME": "1"})
def test_check_failed_state():
    mock_crawler = Mock()
    with patch("boto3.client", Mock(return_value=mock_crawler)):
        mock_crawler.get_crawler = Mock(
            side_effect=[
                return_crawler_respond_results("RUNNING", ""),
                return_crawler_respond_results("READY", "FAILED", "Some error message"),
            ]
        )

        with pytest.raises(Exception) as mock_crawler_error:
            check_state(mock_crawler, "landing")

        assert str(
            mock_crawler_error.value
        ), "$Get crawler $landing state failed: $Get crawler $landing state failed: $Some error message"


def test_get_crawler_name_from_payload():

    crawler_name = get_crawler_name(args=({"CRAWLER_NAME": "landing"},))
    assert "landing" == crawler_name
