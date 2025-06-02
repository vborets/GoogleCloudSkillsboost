#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

BOLD=$(tput bold)
RESET=$(tput sgr0)

# Welcome banner
echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}        Welcome to Dr. Abhishek's Cloud Tutorials         ${NC}"
echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
echo

# Function to validate region input
validate_region() {
  local region=$1
  if [[ "$region" =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt for region with validation
while true; do
  echo -e "${YELLOW}${BOLD}❓ Please enter your preferred GCP region (e.g., us-central1):${NC}"
  read REGION
  if validate_region "$REGION"; then
    export REGION
    echo -e "${GREEN}✅ Using region: ${BOLD}$REGION${NC}"
    echo
    break
  else
    echo -e "${RED}⚠️ Invalid region format. Please try again (e.g., us-central1)${NC}"
  fi
done

# Set environment variables
export SERVICE_NAME=netflix-dataset-service
export FRNT_STG_SRV=frontend-staging-service
export FRNT_PRD_SRV=frontend-production-service

# Function to show spinner while commands run
show_spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Set project and enable services
echo -e "${CYAN}${BOLD}🔧 Configuring GCP project and enabling services...${NC}"
PROJECT_ID=$(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID & show_spinner
gcloud services enable run.googleapis.com & show_spinner
echo -e "${GREEN}✅ Project and services configured${NC}"
echo

# Create Firestore database
echo -e "${CYAN}${BOLD}🗄️ Creating Firestore database in $REGION...${NC}"
(gcloud firestore databases create --location=$REGION --quiet) & show_spinner
echo -e "${GREEN}✅ Firestore database created${NC}"
echo

# Clone repository and set up data
echo -e "${CYAN}${BOLD}📥 Setting up Netflix dataset...${NC}"
if [ -d "pet-theory" ]; then
  echo -e "${YELLOW}Repository exists, updating...${NC}"
  (cd pet-theory && git pull) & show_spinner
else
  (git clone https://github.com/rosera/pet-theory.git) & show_spinner
fi
(cd pet-theory/lab06/firebase-import-csv/solution && npm install && node index.js netflix_titles_original.csv) & show_spinner
echo -e "${GREEN}✅ Dataset imported successfully${NC}"
echo

# Deploy REST API versions
echo -e "${MAGENTA}${BOLD}🚀 Deploying REST API services...${NC}"

# Version 0.1
echo -e "${CYAN}Building REST API v0.1...${NC}"
(cd ~/pet-theory/lab06/firebase-rest-api/solution-01 && npm install && \
 gcloud builds submit --tag gcr.io/$PROJECT_ID/rest-api:0.1 --quiet) & show_spinner
echo -e "${CYAN}Deploying REST API v0.1...${NC}"
(gcloud beta run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/rest-api:0.1 \
 --allow-unauthenticated --region=$REGION --quiet) & show_spinner

# Version 0.2
echo -e "${CYAN}Building REST API v0.2...${NC}"
(cd ~/pet-theory/lab06/firebase-rest-api/solution-02 && npm install && \
 gcloud builds submit --tag gcr.io/$PROJECT_ID/rest-api:0.2 --quiet) & show_spinner
echo -e "${CYAN}Deploying REST API v0.2...${NC}"
(gcloud beta run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/rest-api:0.2 \
 --allow-unauthenticated --region=$REGION --quiet) & show_spinner

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")
echo -e "${GREEN}✅ REST API deployed at: ${BOLD}$SERVICE_URL${NC}"
echo

# Test the API
echo -e "${CYAN}${BOLD}🧪 Testing REST API with sample request...${NC}"
curl -s -X GET $SERVICE_URL/2019 | jq . | head -n 20
echo -e "${GREEN}✅ API test successful${NC}"
echo

# Deploy frontend services
echo -e "${MAGENTA}${BOLD}🖥️ Deploying frontend services...${NC}"

# Configure frontend
echo -e "${CYAN}Configuring frontend to use REST API...${NC}"
(cd ~/pet-theory/lab06/firebase-frontend/public && \
 sed -i 's/^const REST_API_SERVICE = "data\/netflix\.json"/\/\/ const REST_API_SERVICE = "data\/netflix.json"/' app.js && \
 sed -i "1i const REST_API_SERVICE = \"$SERVICE_URL/2020\"" app.js) & show_spinner

# Staging frontend
echo -e "${CYAN}Building staging frontend...${NC}"
(cd ~/pet-theory/lab06/firebase-frontend && npm install && \
 gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-staging:0.1 --quiet) & show_spinner
echo -e "${CYAN}Deploying staging frontend...${NC}"
(gcloud beta run deploy $FRNT_STG_SRV --image gcr.io/$PROJECT_ID/frontend-staging:0.1 \
 --region=$REGION --quiet) & show_spinner

# Production frontend
echo -e "${CYAN}Building production frontend...${NC}"
(cd ~/pet-theory/lab06/firebase-frontend && \
 gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-production:0.1 --quiet) & show_spinner
echo -e "${CYAN}Deploying production frontend...${NC}"
(gcloud beta run deploy $FRNT_PRD_SRV --image gcr.io/$PROJECT_ID/frontend-production:0.1 \
 --region=$REGION --quiet) & show_spinner

# Get frontend URLs
STAGING_URL=$(gcloud run services describe $FRNT_STG_SRV --platform=managed --region=$REGION --format="value(status.url)")
PRODUCTION_URL=$(gcloud run services describe $FRNT_PRD_SRV --platform=managed --region=$REGION --format="value(status.url)")

echo -e "${GREEN}✅ Frontend services deployed:"
echo -e "  Staging: ${BOLD}$STAGING_URL${NC}"
echo -e "  Production: ${BOLD}$PRODUCTION_URL${NC}"
echo

# Completion message
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}              Lab Completed Successfully!               ${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${MAGENTA}${BOLD}💖 If you found this helpful, subscribe to my channel:${NC}"
echo -e "${BLUE}${BOLD}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460${NC}"
echo
