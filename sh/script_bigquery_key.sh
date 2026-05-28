# create products
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/apiproducts" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"name": "BigQuery $UNIQUE_NAME Product", "displayName": "BigQuery $UNIQUE_NAME Product", "approvalType": "auto", "attributes": [{"name": "access", "value": "public" } ], "environments": ["dev"], "createdAt": "1778486511834", "lastModifiedAt": "1778486511834", "operationGroup": {"operationConfigs": [{"apiSource": "MCP-$UNIQUE_NAME-BigQuery", "operations": [{"resource": "/" } ], "quota": {} } ], "operationConfigType": "proxy" } }
EOF

# create test developer
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"email": "${UNIQUE_NAME,,}-test@example.com", "firstName": "$UNIQUE_NAME", "lastName": "User", "userName": "${UNIQUE_NAME,,}-test@example.com"}
EOF

# create app and get key
export BIGQUERY_API_KEY=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers/${UNIQUE_NAME,,}-test@example.com/apps" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF | jq --raw-output '.credentials[0].consumerKey'

{"developerId": "${UNIQUE_NAME,,}-test@example.com", "name": "BigQuery $UNIQUE_NAME App", "apiProducts": ["BigQuery $UNIQUE_NAME Product"]}
EOF
)

echo "Your API key to access the BigQuery MCP Product is: $BIGQUERY_API_KEY"
