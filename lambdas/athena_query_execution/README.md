# Athena Query Execution
This lambda executes AWS Athena Queries via a simple Python Lambda using a boto3
`start_query_execution` call.  It requires the following parameters from
the input:
* `SQL_QUERY_FILES`: a comma-separated list of sql query-files to be executed, e.g. `"foo.sql,bar.sql"`
* `ATHENA_DATABASE`: the name of the Athena Database, e.g. `"trusted"`
* `WORKGROUP`: the Athena Workgroup, e.g. `"DataConsumers"`

A complete set of parameters looks something like this:
````json
{
  "SQL_QUERY_FILES": "foo.sql,bar.sql",
  "ATHENA_DATABASE": "trusted",
  "WORKGROUP": "DataConsumers"
}
````

## Testing
Tests can be executed via a `PYTHONPATH=. pytest .` from within the lambda_triggers directory.
