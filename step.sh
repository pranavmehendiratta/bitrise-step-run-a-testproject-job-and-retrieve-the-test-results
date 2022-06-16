#!/bin/bash
set -ex

execution_id=$(curl -X POST "https://api.testproject.io/v2/projects/$project_id/jobs/$job_id/run" -H "accept: application/json" -H "Authorization: $api_key" -H "Content-Type: application/json" --data-binary '{"queue": true, "restartDriver": true, "testRetries": 1}' | jq -r '.id')

echo $execution_id

status="Not ready"
report="Invalid Url"
while [ "$status" != "Passed" ] && [ "$status" != "Failed" ]
do
    response=$(curl -X GET "https://api.testproject.io/v2/projects/$project_id/jobs/$job_id/executions/$execution_id/state" -H "accept: application/json" -H "Authorization: $api_key" -H "Content-Type: application/json")
    echo $response
    status=$(jq -r '.state' <<< "$response")
    report=$(jq -r '.report' <<< "$response")
    sleep 30
    echo "trying again...."
done

echo "Final status"
message="$status: $report"
echo $status
echo $report
echo $message

# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:

envman add --key testproject_status_message --value "$message"

# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.

if [ $status == "Failed" ]
then
  exit 1
else
  exit 0  
fi

