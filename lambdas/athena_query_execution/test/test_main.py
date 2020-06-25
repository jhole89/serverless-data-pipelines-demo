import uuid
from typing import *
from unittest.mock import patch, Mock

import pytest

from athena_query_execution.src.main import handler, get_handler_input_args, check_state


sql_query_files = "abc.sql"
athena_database = "an_athena_database"
workgroup = "a_workgroup"
table_name = "a_table"


def test_handler():
    mock_athena = Mock()
    test_id = uuid.uuid4()
    with patch("boto3.client", Mock(return_value=mock_athena)):
        mock_athena.start_query_execution = Mock(return_value={"QueryExecutionId": test_id})
        mock_athena.get_query_execution = Mock(
            return_value={
                "QueryExecution": {"QueryExecutionId": test_id, "Status": {"State": "SUCCEEDED"},}
            }
        )

        query_ids = handler(
            {
                "SQL_QUERY_FILES": "CVAS.sql",
                "ATHENA_DATABASE": athena_database,
                "WORKGROUP": workgroup,
                "TABLENAME": table_name,
            },
        )
        assert query_ids == [test_id]


def test_get_handler_args():

    (
        actual_sql_query_files,
        actual_table_name,
        actual_athena_database,
        actual_workgroup,
    ) = get_handler_input_args(
        args=(
            {
                "SQL_QUERY_FILES": sql_query_files,
                "ATHENA_DATABASE": athena_database,
                "WORKGROUP": workgroup,
                "TABLENAME": table_name,
            },
        )
    )
    assert actual_sql_query_files == sql_query_files
    assert actual_table_name == table_name
    assert actual_athena_database == athena_database
    assert actual_workgroup == workgroup


def return_query_execution_results(test_id, state) -> Dict[str, Any]:
    return {
        "QueryExecution": {
            "QueryExecutionId": test_id,
            "Status": {"State": state, "StateChangeReason": "xyz"},
        }
    }


@pytest.mark.timeout(60)
def test_check_state():
    mock_athena = Mock()
    test_id = str(uuid.uuid4())
    with patch("boto3.client", Mock(return_value=mock_athena)):
        mock_athena.get_query_execution = Mock(
            side_effect=[
                return_query_execution_results(test_id, "QUEUED"),
                return_query_execution_results(test_id, "RUNNING"),
                return_query_execution_results(test_id, "SUCCEEDED"),
            ]
        )
        state = check_state(mock_athena, sql_query_files, test_id)
        assert state == "SUCCEEDED"


@pytest.mark.timeout(60)
def test_check_state_failure():
    mock_athena = Mock()
    test_id = str(uuid.uuid4())
    with patch("boto3.client", Mock(return_value=mock_athena)):
        mock_athena.get_query_execution = Mock(
            side_effect=[
                return_query_execution_results(test_id, "QUEUED"),
                return_query_execution_results(test_id, "RUNNING"),
                return_query_execution_results(test_id, "FAILED"),
            ]
        )
        with pytest.raises(Exception) as state_exception:
            check_state(mock_athena, sql_query_files, test_id)
        assert (
            str(state_exception.value)
            == f"Query {sql_query_files} failed with execution {test_id}: xyz"
        )
