#!/bin/bash
# Define color variables
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

#----------------------------------------------------start--------------------------------------------------#


echo "${BG_BLUE}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo "${BG_BLUE}${BOLD}║         WELCOME TO DR ABHISHEK CLOUD          ║${RESET}"
echo "${BG_BLUE}${BOLD}║          TUTORIAL                             ║${RESET}"
echo "${BG_BLUE}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo
echo "${BOLD}Project ID: ${GREEN}$DEVSHELL_PROJECT_ID${RESET}"

# Get current zone and set region
export ZONE=$(gcloud config get-value compute/zone)
if [ -z "$ZONE" ]; then
  echo "${RED}${BOLD}Error: Compute zone not set. Please set it using:${RESET}"
  echo "gcloud config set compute/zone YOUR_ZONE"
  exit 1
fi

export REGION="${ZONE%-*}"
echo "${BOLD}Zone: ${GREEN}$ZONE${RESET}"
echo "${BOLD}Region: ${GREEN}$REGION${RESET}"
echo

echo "${BG_MAGENTA}${BOLD}Starting Execution...${RESET}"
echo

# Create Dataplex Lake
echo "${CYAN}${BOLD}Creating Dataplex Lake...${RESET}"
gcloud alpha dataplex lakes create customer-lake \
  --display-name="Customer-Lake" \
  --location=$REGION \
  --labels="key_1=$KEY_1,value_1=$VALUE_1" || {
  echo "${RED}${BOLD}Error creating Dataplex lake${RESET}"
  exit 1
}

# Create Public Zone
echo "${CYAN}${BOLD}Creating Public Zone...${RESET}"
gcloud dataplex zones create public-zone \
  --lake=customer-lake \
  --location=$REGION \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --display-name="Public-Zone" || {
  echo "${RED}${BOLD}Error creating public zone${RESET}"
  exit 1
}

# Create Storage Bucket Asset
echo "${CYAN}${BOLD}Creating Customer Raw Data Asset...${RESET}"
gcloud dataplex assets create customer-raw-data --location=$REGION \
  --lake=customer-lake --zone=public-zone \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-bucket \
  --discovery-enabled \
  --display-name="Customer Raw Data" || {
  echo "${RED}${BOLD}Error creating raw data asset${RESET}"
  exit 1
}

# Create BigQuery Dataset Asset
echo "${CYAN}${BOLD}Creating Customer Reference Data Asset...${RESET}"
gcloud dataplex assets create customer-reference-data --location=$REGION \
  --lake=customer-lake --zone=public-zone \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_reference_data \
  --display-name="Customer Reference Data" || {
  echo "${RED}${BOLD}Error creating reference data asset${RESET}"
  exit 1
}

# Completion Message
echo
echo "${BG_GREEN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}║        DO LIKE THE VIDEO AND SUBSCRIBE TO CHANNEL!        ║${RESET}"
echo "${BG_GREEN}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}Next Steps:${RESET}"
echo "${BLUE}${BOLD}Click here to create entities: ${RESET}"
echo "${WHITE}https://console.cloud.google.com/dataplex/lakes/customer-lake/zones/public-zone/create-entity;location=$REGION?project=$DEVSHELL_PROJECT_ID${RESET}"
echo

# Learning Resources
echo "${YELLOW}${BOLD}For more Google Cloud tutorials:${RESET}"
echo "${BLUE}${BOLD}Subscribe to Dr. Abhishek's YouTube channel:${RESET}"
echo "${WHITE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

#-----------------------------------------------------end----------------------------------------------------------#
