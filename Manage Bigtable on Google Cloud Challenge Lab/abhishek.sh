#!/bin/bash

# Color definitions
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Display welcome message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  WELCOME TO DR. ABHISHEK CLOUD TUTORIALS  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to subscribe to Dr. Abhishek's YouTube channel:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460/videos${RESET_FORMAT}"
echo

# Get user input for zones
echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Please enter your zone information               ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
echo
read -p "${BLUE_TEXT}${BOLD_TEXT}ENTER ZONE 1: ${RESET_FORMAT}" ZONE
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}NOTE: ZONE 2 must be different from ZONE 1${RESET_FORMAT}"
read -p "${BLUE_TEXT}${BOLD_TEXT}ENTER ZONE 2: ${RESET_FORMAT}" ZONE_2
echo

export REGION="${ZONE%-*}"
export PROJECT_ID=$(gcloud config get-value project)

# Configure Dataflow service
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Configuring Dataflow service...                  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com
gcloud services enable dataflow.googleapis.com
echo "${GREEN_TEXT}✅ Dataflow service configured${RESET_FORMAT}"
echo

# Create Bigtable instance
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Creating Bigtable instance...                    ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud bigtable instances create ecommerce-recommendations \
  --display-name=ecommerce-recommendations \
  --cluster-storage-type=SSD \
  --cluster-config="id=ecommerce-recommendations-c1,zone=$ZONE"
echo "${GREEN_TEXT}✅ Bigtable instance created${RESET_FORMAT}"
echo

# Configure autoscaling for cluster 1
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring autoscaling for cluster 1...${RESET_FORMAT}"
gcloud bigtable clusters update ecommerce-recommendations-c1 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 
echo "${GREEN_TEXT}✅ Autoscaling configured for cluster 1${RESET_FORMAT}"
echo

# Create storage bucket
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Creating storage bucket...                      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gsutil mb gs://$PROJECT_ID
echo "${GREEN_TEXT}✅ Storage bucket created${RESET_FORMAT}"
echo

# Create Bigtable tables
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Creating Bigtable tables...                     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud bigtable instances tables create SessionHistory \
    --instance=ecommerce-recommendations \
    --project=$PROJECT_ID \
    --column-families=Engagements,Sales

gcloud bigtable instances tables create PersonalizedProducts \
    --instance=ecommerce-recommendations \
    --project=$PROJECT_ID \
    --column-families=Recommendations
echo "${GREEN_TEXT}✅ Bigtable tables created${RESET_FORMAT}"
echo

# Import data using Dataflow
echo "${MAGENTA_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}  Importing data using Dataflow...              ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
echo "${YELLOW_TEXT}This may take several minutes...${RESET_FORMAT}"

gcloud dataflow jobs run import-sessions \
  --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
  --region $REGION \
  --staging-location gs://$PROJECT_ID/temp \
  --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

gcloud dataflow jobs run import-recommendations \
  --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
  --region $REGION \
  --staging-location gs://$PROJECT_ID/temp \
  --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001

echo "${GREEN_TEXT}✅ Data import jobs started${RESET_FORMAT}"
echo

# Create second cluster
echo "${CYAN_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Creating second cluster...                      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud bigtable clusters create ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --zone=$ZONE_2

gcloud bigtable clusters update ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 
echo "${GREEN_TEXT}✅ Second cluster created and configured${RESET_FORMAT}"
echo

# Create and restore backup
echo "${MAGENTA_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}  Creating and restoring backup...              ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud bigtable backups create PersonalizedProducts_7 \
  --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 \
  --table=PersonalizedProducts \
  --retention-period=7d 

gcloud bigtable instances tables restore \
  --source=projects/$PROJECT_ID/instances/ecommerce-recommendations/clusters/ecommerce-recommendations-c1/backups/PersonalizedProducts_7 \
  --async \
  --destination=PersonalizedProducts_7_restored \
  --destination-instance=ecommerce-recommendations \
  --project=$PROJECT_ID

echo "${YELLOW_TEXT}Waiting for backup operations to complete...${RESET_FORMAT}"
sleep 100
echo "${GREEN_TEXT}✅ Backup operations completed${RESET_FORMAT}"
echo

# Completion message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎉  FOLLOW THE VIDEO CAREFULLY !  🎉${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Thank you for following Dr. Abhishek's Cloud Tutorial!${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}For more tutorials, please subscribe to:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460/videos${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}You can monitor your Dataflow jobs at:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/dataflow/jobs?project=${PROJECT_ID}${RESET_FORMAT}"
echo
