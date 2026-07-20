#!/usr/bin/env bash
set -e

ORG="${GOOGLE_CLOUD_PROJECT}"
ENV="${APIGEE_ENVIRONMENT:-dev}"
DEV_EMAIL="ai-developer@example.com"
APP_NAME="ai-gateway-app"

TOKEN=$(gcloud auth print-access-token)

echo "1. Registering Developer (${DEV_EMAIL})..."
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/${ORG}/developers" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${DEV_EMAIL}\",
    \"firstName\": \"AI\",
    \"lastName\": \"Developer\",
    \"userName\": \"aideveloper\"
  }" > /dev/null || true

echo "2. Fetching deployed API Products..."
PRODUCTS_JSON=$(curl -s -H "Authorization: Bearer ${TOKEN}" "https://apigee.googleapis.com/v1/organizations/${ORG}/apiproducts" | jq -r '.apiProduct[].name')
PROD_ARRAY=$(echo "$PRODUCTS_JSON" | jq -R . | jq -s .)

echo "3. Registering Developer App (${APP_NAME})..."
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/${ORG}/developers/${DEV_EMAIL}/apps" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${APP_NAME}\",
    \"apiProducts\": ${PROD_ARRAY}
  }" > /dev/null || true

echo "4. Retrieving API Key..."
API_KEY=$(curl -s -H "Authorization: Bearer ${TOKEN}" "https://apigee.googleapis.com/v1/organizations/${ORG}/developers/${DEV_EMAIL}/apps/${APP_NAME}" | jq -r '.credentials[0].consumerKey')

echo ""
echo "=================================================================="
echo "🎉 SUCCESS! Your Apigee AI Gateway is fully operational."
echo "Your API Key: ${API_KEY}"
echo "=================================================================="
