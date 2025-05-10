#!/bin/bash

# Define colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Display header
echo -e "\n${BLUE}${BOLD}"
echo "╔════════════════════════════════════════════════╗"
echo "║       CLOUD FUNCTIONS DEPLOYMENT        ║"
echo "║           by Dr. Abhishek                      ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}${RESET}"

# Get region input with validation
while true; do
    echo -e "${YELLOW}${BOLD}Step 1: Enter your GCP region (e.g., us-central1)${NC}${RESET}"
    read -p "Region: " REGION
    
    if [ -z "$REGION" ]; then
        echo -e "${RED}Error: Region cannot be empty. Please try again.${NC}"
    elif ! [[ $REGION =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid region format. Example: us-central1${NC}"
    else
        break
    fi
done

# Create working directory
echo -e "\n${YELLOW}${BOLD}Step 2: Setting up project directory...${NC}${RESET}"
mkdir -p ~/hello-go && cd ~/hello-go || {
    echo -e "${RED}Failed to create working directory. Check permissions.${NC}"
    exit 1
}

# Create main.go file
echo -e "\n${YELLOW}${BOLD}Step 3: Creating Go function source...${NC}${RESET}"
cat > main.go <<'EOF_END'
package function

import (
    "fmt"
    "net/http"
)

// HelloGo is the entry point
func HelloGo(w http.ResponseWriter, r *http.Request) {
    fmt.Fprint(w, "Hello from Cloud Functions (Go 2nd Gen)!")
}
EOF_END

# Create go.mod file
cat > go.mod <<'EOF_END'
module example.com/hellogo

go 1.21
EOF_END

echo -e "${GREEN}✓ Created Go source files${NC}"

# Deploy HTTP-triggered function
echo -e "\n${YELLOW}${BOLD}Step 4: Deploying HTTP-triggered function...${NC}${RESET}"
if gcloud functions deploy cf-go \
  --gen2 \
  --runtime=go121 \
  --region=$REGION \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=HelloGo \
  --source=. \
  --min-instances=5 2>&1 | tee /tmp/cf-deploy.log; then
    echo -e "\n${GREEN}✓ Successfully deployed HTTP function${NC}"
else
    echo -e "\n${RED}✗ Failed to deploy HTTP function. Error details:${NC}"
    cat /tmp/cf-deploy.log
    echo -e "\n${YELLOW}Possible solutions:"
    echo -e "1. Verify Cloud Functions API is enabled"
    echo -e "2. Check your gcloud authentication"
    echo -e "3. Ensure you have sufficient permissions${NC}"
    rm /tmp/cf-deploy.log
    exit 1
fi
rm /tmp/cf-deploy.log

# Deploy Pub/Sub-triggered function (with automatic confirmation)
echo -e "\n${YELLOW}${BOLD}Step 5: Deploying Pub/Sub-triggered function...${NC}${RESET}"
echo "n" | gcloud functions deploy cf-pubsub \
  --gen2 \
  --region=$REGION \
  --runtime=go121 \
  --trigger-topic=cf-pubsub \
  --min-instances=5 \
  --entry-point=helloWorld \
  --source=. \
  --allow-unauthenticated 2>&1 | tee /tmp/cf-pubsub.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "\n${GREEN}✓ Successfully deployed Pub/Sub function${NC}"
else
    echo -e "\n${RED}✗ Failed to deploy Pub/Sub function. Error details:${NC}"
    cat /tmp/cf-pubsub.log
    echo -e "\n${YELLOW}Note: The topic 'cf-pubsub' will be automatically created${NC}"
    rm /tmp/cf-pubsub.log
fi

# Completion message
echo -e "\n${GREEN}${BOLD}Deployment completed!${NC}${RESET}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. Test your HTTP function:"
echo -e "   gcloud functions describe cf-go --region $REGION --gen2"
echo -e "2. Test your Pub/Sub function:"
echo -e "   gcloud pubsub topics publish cf-pubsub --message='Hello World'"
echo -e "\n${BLUE}For more tutorials:${NC}"
echo -e "Visit: https://www.youtube.com/@drabhishek.5460"
