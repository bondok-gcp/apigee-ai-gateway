# get environment variables
export APIGEE_ENVIRONMENT=$(apigeecli environments list -o $GOOGLE_CLOUD_PROJECT --default-token | jq --raw-output '.[0]')
echo "Your Apigee environment is: $APIGEE_ENVIRONMENT"
export APIGEE_HOST=$(apigeecli envgroups list -o $GOOGLE_CLOUD_PROJECT --default-token | jq --raw-output '.environmentGroups[0].hostnames[-1]')
echo "Your Apigee host is: $APIGEE_HOST"
