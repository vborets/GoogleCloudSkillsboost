#!/bin/bash
# Color definitions
BLUE=$'\033[0;94m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
RED=$'\033[0;91m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Function to display section headers
section() {
    echo ""
    echo "${BLUE}${BOLD}============================================${RESET}"
    echo "${BLUE}${BOLD}$1${RESET}"
    echo "${BLUE}${BOLD}============================================${RESET}"
    echo ""
}

# Function to show a spinner while commands run
spinner() {
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

# Welcome message
echo ""
echo "${GREEN}${BOLD}🚀 Welcome to Dr Abhishek Cloud Tutorials 🚀${RESET}"
echo ""

# Get zone inputs
echo "${YELLOW}${BOLD}Please enter your preferred zones:${RESET}"
echo ""
read -p "ENTER ZONE 1 (e.g., us-central1-a): " ZONE
echo ""
echo "${YELLOW}${BOLD}Note: ZONE 2 must be different from ZONE 1${RESET}"
read -p "ENTER ZONE 2 (e.g., us-central1-b): " ZONE_2

# Set region from zone
export REGION="${ZONE%-*}"

section "1. Configuring Dataflow Service"
echo "${YELLOW}Reconfiguring Dataflow service...${RESET}"
(gcloud services disable dataflow.googleapis.com > /dev/null 2>&1; \
 gcloud services enable dataflow.googleapis.com > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Dataflow service configured${RESET}"

section "2. Creating Bigtable Instance"
echo "${YELLOW}Creating ecommerce-recommendations instance...${RESET}"
(gcloud bigtable instances create ecommerce-recommendations \
  --display-name=ecommerce-recommendations \
  --cluster-storage-type=SSD \
  --cluster-config="id=ecommerce-recommendations-c1,zone=$ZONE" > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Bigtable instance created${RESET}"

section "3. Configuring Cluster Autoscaling"
echo "${YELLOW}Updating cluster autoscaling settings...${RESET}"
(gcloud bigtable clusters update ecommerce-recommendations-c1 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Autoscaling configured${RESET}"

section "4. Creating Storage Bucket"
echo "${YELLOW}Creating storage bucket...${RESET}"
(gsutil mb gs://$DEVSHELL_PROJECT_ID > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Storage bucket created${RESET}"

section "5. Creating Bigtable Tables"
echo "${YELLOW}Creating SessionHistory table...${RESET}"
(gcloud bigtable instances tables create SessionHistory \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Engagements,Sales > /dev/null 2>&1) & spinner

echo "${YELLOW}Creating PersonalizedProducts table...${RESET}"
(gcloud bigtable instances tables create PersonalizedProducts \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Recommendations > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Tables created successfully${RESET}"

section "6. Importing Data to Bigtable"
echo "${YELLOW}Importing session data...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 > /dev/null 2>&1) & spinner

echo "${YELLOW}Importing recommendation data...${RESET}"
(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Data import completed${RESET}"

section "7. Creating Second Cluster"
echo "${YELLOW}Creating second cluster in zone $ZONE_2...${RESET}"
(gcloud bigtable clusters create ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --zone=$ZONE_2 > /dev/null 2>&1) & spinner

echo "${YELLOW}Configuring autoscaling for second cluster...${RESET}"
(gcloud bigtable clusters update ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Second cluster configured${RESET}"

section "8. Creating and Restoring Backup"
echo "${YELLOW}Creating backup of PersonalizedProducts table...${RESET}"
(gcloud bigtable backups create PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 \
  --table=PersonalizedProducts \
  --retention-period=7d > /dev/null 2>&1) & spinner

echo "${YELLOW}Restoring backup to new table...${RESET}"
(gcloud bigtable instances tables restore \
--source=projects/$DEVSHELL_PROJECT_ID/instances/ecommerce-recommendations/clusters/ecommerce-recommendations-c1/backups/PersonalizedProducts_7 \
--async \
--destination=PersonalizedProducts_7_restored \
--destination-instance=ecommerce-recommendations \
--project=$DEVSHELL_PROJECT_ID > /dev/null 2>&1) & spinner

echo "${YELLOW}Waiting for restore to complete...${RESET}"
sleep 100
echo "${GREEN}✅ Backup restored successfully${RESET}"

section "9. Final Data Import"
echo "${YELLOW}Running final data imports...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 > /dev/null 2>&1) & spinner

(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Final data imports completed${RESET}"

# Completion message
echo ""
echo "${GREEN}${BOLD}🎉 Now Follow Video Carefully! 🎉${RESET}"
echo ""
echo "${BOLD}You can monitor your Dataflow jobs at:${RESET}"
echo -e "${BLUE}${BOLD}https://console.cloud.google.com/dataflow/jobs?referrer=search&project=${DEVSHELL_PROJECT_ID}${RESET}"
echo ""
