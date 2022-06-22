#!/bin/bash
set -ex

execution_id=$(curl -X POST "https://api.testproject.io/v2/projects/$project_id/jobs/$job_id/run" -H "accept: application/json" -H "Authorization: $api_key" -H "Content-Type: application/json" --data-binary '{"queue": true, "restartDriver": true, "testRetries": 1}' | jq -r '.id')

status="Not ready"
report="Invalid Url"
while [ "$status" != "Passed" ] && [ "$status" != "Failed" ]
do
    response=$(curl -X GET "https://api.testproject.io/v2/projects/$project_id/jobs/$job_id/executions/$execution_id/state" -H "accept: application/json" -H "Authorization: $api_key" -H "Content-Type: application/json")
    status=$(jq -r '.state' <<< "$response")
    report=$(jq -r '.report' <<< "$response")
    sleep 30
done

message="$status: $report"

# ------------------------------------------------------------
# Put the testProject ui suite result in an env variable for 
# slack to read
# ------------------------------------------------------------

envman add --key testproject_status_message --value "$message"

# ------------------------------------------------------------
# If the ui tests failed then fail the build
# ------------------------------------------------------------

if [ $status == "Failed" ]
then
  exit 1
else
  exit 0  
fi
