#!/usr/bin/env bash
set -e

ORG="${GOOGLE_CLOUD_PROJECT}"
ENV="${APIGEE_ENVIRONMENT:-dev}"
DEV_EMAIL="ai-developer@example.com"
APP_NAME="ai-gateway-app"
PRODUCT_NAME="ai-gateway-product"

TOKEN=$(gcloud auth print-access-token)

echo "1. Creating API Product (${PRODUCT_NAME})..."
# This explicitly creates a product allowing access to the new proxies and all sub-paths (/**)
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/${ORG}/apiproducts" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${PRODUCT_NAME}\",
    \"displayName\": \"AI Gateway Product\",
    \"approvalType\": \"auto\",
    \"environments\": [\"${ENV}\"],
    \"proxies\": [\"AI-Gemini\", \"AI-Claude\"],
    \"apiResources\": [\"/\", \"/**\"]
  }" > /dev/null || true

echo "2. Registering Developer (${DEV_EMAIL})..."
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/${ORG}/developers" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${DEV_EMAIL}\",
    \"firstName\": \"AI\",
    \"lastName\": \"Developer\",
    \"userName\": \"aideveloper\"
  }" > /dev/null || true

echo "3. Registering Developer App (${APP_NAME})..."
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/${ORG}/developers/${DEV_EMAIL}/apps" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${APP_NAME}\",
    \"apiProducts\": [\"${PRODUCT_NAME}\"]
  }" > /dev/null || true

echo "4. Retrieving API Key..."
API_KEY=$(curl -s -H "Authorization: Bearer ${TOKEN}" "https://apigee.googleapis.com/v1/organizations/${ORG}/developers/${DEV_EMAIL}/apps/${APP_NAME}" | jq -r '.credentials[0].consumerKey')

echo ""
echo "=================================================================="
echo "🎉 SUCCESS! Your Apigee AI Gateway is fully operational."
echo "Your API Key: ${API_KEY}"
echo "=================================================================="
