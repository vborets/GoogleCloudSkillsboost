#!/bin/bash

# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

# Welcome message with ASCII art
echo ""
echo "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}║                   🎉 WELCOME TO DR. ABHISHEK! 🎉           ║${RESET}"
echo "${CYAN}${BOLD}║                                                              ║${RESET}"
echo "${CYAN}${BOLD}║          Thank you for using this Apigee setup script!      ║${RESET}"
echo "${CYAN}${BOLD}║                                                              ║${RESET}"
echo "${CYAN}${BOLD}║     📺 YouTube: https://www.youtube.com/@drabhishek.5460    ║${RESET}"
echo "${CYAN}${BOLD}║                                                              ║${RESET}"
echo "${CYAN}${BOLD}║           👍 Like • 🔔 Subscribe • 💬 Comment               ║${RESET}"
echo "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

echo "🚀 Starting Apigee configuration..."
echo ""

# Display current project
echo "${YELLOW}${BOLD}Current Project Configuration:${RESET}"
gcloud auth list
echo ""

# Enable Translate API
echo "🔧 Enabling Translate API..."
gcloud services enable translate.googleapis.com --project=$DEVSHELL_PROJECT_ID

# Create service account
echo "👤 Creating Apigee Proxy Service Account..."
gcloud iam service-accounts create apigee-proxy \
  --display-name "Apigee Proxy Service"

# List service accounts
echo "📋 Available Service Accounts:"
gcloud iam service-accounts list --project=$DEVSHELL_PROJECT_ID

echo ""
echo "${GREEN}${BOLD}Project ID: $DEVSHELL_PROJECT_ID${RESET}"
echo ""

# Add IAM policy binding
echo "🔐 Assigning Logging Role..."
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:apigee-proxy@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Create translate product JSON
echo "📦 Creating Translate API Product Configuration..."
cat > translate-product.json <<EOF_CP
{
  "name": "translate-product",
  "displayName": "translate-product",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    },
    {
      "name": "full-access",
      "value": "yes"
    }
  ],
  "description": "API product for translation services",
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "translate-v1",
        "operations": [
          {
            "resource": "/",
            "methods": [
              "GET",
              "POST"
            ]
          }
        ],
        "quota": {
          "limit": "10",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_CP

# Create API product
echo "🌐 Creating API Product..."
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @translate-product.json

echo ""
echo "✅ API Product created successfully!"
echo ""

# Create developer
echo "👨‍💻 Creating Developer Account..."
curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/developers" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Joe",
    "lastName": "Developer",
    "userName": "joe",  
    "email": "joe@example.com"
  }'

echo ""
echo "✅ Developer account created successfully!"
echo ""

# Wait for instance to be active
echo "⏳ Setting up Apigee Runtime Instance..."
echo "This may take a few minutes..."
export INSTANCE_NAME=eval-instance
export ENV_NAME=eval
export PREV_INSTANCE_STATE=""

echo "Waiting for runtime instance ${INSTANCE_NAME} to be active"
while : ; do
  export INSTANCE_STATE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}" | jq "select(.state != null) | .state" --raw-output)
  [[ "${INSTANCE_STATE}" == "${PREV_INSTANCE_STATE}" ]] || (echo; echo "INSTANCE_STATE=${INSTANCE_STATE}")
  export PREV_INSTANCE_STATE=${INSTANCE_STATE}
  [[ "${INSTANCE_STATE}" != "ACTIVE" ]] || break
  echo -n "."
  sleep 5
done

echo ""
echo "✅ Instance created, waiting for environment ${ENV_NAME} to be attached to instance"

while : ; do
  export ATTACHMENT_DONE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}/attachments" | jq "select(.attachments != null) | .attachments[] | select(.environment == \"${ENV_NAME}\") | .environment" --join-output)
  [[ "${ATTACHMENT_DONE}" != "${ENV_NAME}" ]] || break
  echo -n "."
  sleep 5
done

echo ""
echo "${GREEN}${BOLD}*** ORG IS READY TO USE ***${RESET}"
echo ""

# Important links and information
echo "${YELLOW}${BOLD}📋 NEXT STEPS:${RESET}"
echo ""
echo "${YELLOW}${BOLD}1. Create an Apigee proxy:${RESET}"
echo "   🔗 https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"
echo ""
echo "${YELLOW}${BOLD}2. Translate API Endpoint:${RESET}"
echo "   🌐 https://translation.googleapis.com/language/translate/v2"
echo ""
echo "${YELLOW}${BOLD}3. Service Account Email:${RESET}"
echo "   📧 apigee-proxy@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"
echo ""

# Final message
echo "${CYAN}${BOLD}🎊 APIGEE SETUP COMPLETED SUCCESSFULLY! 🎊${RESET}"
echo ""
echo "${CYAN}${BOLD}✨ Thank you for using this script! ✨${RESET}"
echo ""
echo "${CYAN}${BOLD}📺 For more tutorials, visit my YouTube channel:${RESET}"
echo "${CYAN}${BOLD}   https://www.youtube.com/@drabhishek.5460${RESET}"
echo ""
echo "${CYAN}${BOLD}🐬 Happy coding with Apigee! 🐬${RESET}"
echo ""
