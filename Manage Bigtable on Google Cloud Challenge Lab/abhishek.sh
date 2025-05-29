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

# Function to display section headers
section() {
    echo ""
    echo "${BG_BLUE}${BOLD}=== $1 ===${RESET}"
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

#----------------------------------------------------start--------------------------------------------------#

clear
echo "${BG_MAGENTA}${BOLD}Welcome To Dr Abhishek Cloud Tutorials${RESET}"
echo ""

# Get zone input if not already set
if [ -z "$ZONE" ]; then
    echo "${YELLOW}${BOLD}Please enter your primary zone (e.g., us-central1-a):${RESET}"
    read -p "Zone: " ZONE
    echo ""
    echo "${YELLOW}${BOLD}Please enter your secondary zone (must be different from $ZONE):${RESET}"
    read -p "Zone 2: " ZONE2
    echo ""
fi

export REGION="${ZONE%-*}"

section "1. Configuring Dataflow Service"
echo "${YELLOW}Configuring Dataflow API...${RESET}"
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
echo "${YELLOW}Setting up autoscaling for primary cluster...${RESET}"
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

section "6. Importing Initial Data"
echo "${YELLOW}Importing session data...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 > /dev/null 2>&1) & spinner

echo "${YELLOW}Importing recommendation data...${RESET}"
(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Initial data import completed${RESET}"

section "7. Creating Second Cluster"
echo "${YELLOW}Creating secondary cluster in zone $ZONE2...${RESET}"
(gcloud bigtable clusters create ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --zone=$ZONE2 > /dev/null 2>&1) & spinner

echo "${YELLOW}Configuring autoscaling for secondary cluster...${RESET}"
(gcloud bigtable clusters update ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Secondary cluster configured${RESET}"

section "8. Backup and Restore Operations"
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
for i in {1..100}; do
    echo -ne "${YELLOW}⏳ $((100 - i)) seconds remaining...${RESET}\r"
    sleep 1
done
echo -ne "${GREEN}✅ Backup restored successfully${RESET}          \n"

section "9. Final Data Import"
echo "${YELLOW}Running final data imports...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 > /dev/null 2>&1) & spinner

(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Final data imports completed${RESET}"

section "10. Verification"
echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}Check The Score${RESET}" "${GREEN}${BOLD}Up to Task 4${RESET}"
echo "${YELLOW}Waiting for 5 minutes before cleanup...${RESET}"
for i in {300..1}; do
    echo -ne "${YELLOW}⏳ $i seconds remaining...${RESET}\r"
    sleep 1
done
echo -ne "${GREEN}✅ Verification period complete${RESET}          \n"

section "11. Cleanup"
echo "${YELLOW}Deleting backup...${RESET}"
(gcloud bigtable backups delete PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 --quiet > /dev/null 2>&1) & spinner

echo "${YELLOW}Deleting Bigtable instance...${RESET}"
(gcloud bigtable instances delete ecommerce-recommendations --quiet > /dev/null 2>&1) & spinner
echo "${GREEN}✅ Cleanup completed${RESET}"

echo ""
echo "${BG_GREEN}${BLACK}${BOLD}Do like the video & Subscribe the channel!${RESET}"
echo ""
echo "${BOLD}You can check your Dataflow jobs at:${RESET}"
echo "${BLUE}${BOLD}https://console.cloud.google.com/dataflow/jobs?project=${DEVSHELL_PROJECT_ID}${RESET}"
echo ""

#-----------------------------------------------------end----------------------------------------------------------#
