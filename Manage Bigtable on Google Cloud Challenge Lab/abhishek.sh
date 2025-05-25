#!/bin/bash
# Define color variables with improved formatting
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

# Spinner function
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

# Progress bar function
progress_bar() {
    local duration=${1}
    local columns=$(tput cols)
    local space=$((columns-20))
    printf "${BLUE}${BOLD}Progress: ["
    for ((i=0; i<space; i++)); do printf " "; done
    printf "]${RESET}\r"
    printf "${BLUE}${BOLD}Progress: ["
    for ((i=0; i<space; i++)); do
        printf "${GREEN}${BOLD}#${RESET}"
        sleep $duration
    done
    printf "]${RESET}\n"
}

# Header function
header() {
    clear
    echo "${BG_MAGENTA}${BOLD}${WHITE}============================================${RESET}"
    echo "${BG_MAGENTA}${BOLD}${WHITE}  Dr. Abhishek's Cloud Bigtable Lab         ${RESET}"
    echo "${BG_MAGENTA}${BOLD}${WHITE}============================================${RESET}"
    echo
}

# Welcome message
welcome() {
    header
    echo "${CYAN}${BOLD}Welcome to Dr abhishek cloud tutorials !${RESET}"
    echo "${YELLOW}Subscribe to my channel: https://www.youtube.com/@drabhishek.5460${RESET}"
    echo
    echo "${GREEN}${BOLD}Starting execution in 3 seconds...${RESET}"
    sleep 3
}

#----------------------------------------------------start--------------------------------------------------#
welcome

echo "${BG_MAGENTA}${BOLD}${WHITE}=== INITIAL SETUP ===${RESET}"
export REGION="${ZONE%-*}"

echo "${YELLOW}${BOLD}Configuring Dataflow service...${RESET}"
(gcloud services disable dataflow.googleapis.com >/dev/null 2>&1) & spinner
(gcloud services enable dataflow.googleapis.com >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Dataflow service configured${RESET}"

echo "${YELLOW}${BOLD}Creating Bigtable instance...${RESET}"
(gcloud bigtable instances create ecommerce-recommendations \
  --display-name=ecommerce-recommendations \
  --cluster-storage-type=SSD \
  --cluster-config="id=ecommerce-recommendations-c1,zone=$ZONE" >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Bigtable instance created${RESET}"

echo "${YELLOW}${BOLD}Configuring autoscaling for cluster...${RESET}"
(gcloud bigtable clusters update ecommerce-recommendations-c1 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Autoscaling configured${RESET}"

echo "${YELLOW}${BOLD}Creating storage bucket...${RESET}"
(gsutil mb gs://$DEVSHELL_PROJECT_ID >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Storage bucket created${RESET}"

echo "${YELLOW}${BOLD}Creating Bigtable tables...${RESET}"
(gcloud bigtable instances tables create SessionHistory \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Engagements,Sales >/dev/null 2>&1) & spinner

(gcloud bigtable instances tables create PersonalizedProducts \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Recommendations >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Tables created${RESET}"

echo "${BG_MAGENTA}${BOLD}${WHITE}=== DATA IMPORT ===${RESET}"
echo "${YELLOW}${BOLD}Importing session data...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Session data imported${RESET}"

echo "${YELLOW}${BOLD}Importing recommendations data...${RESET}"
(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Recommendations data imported${RESET}"

echo "${BG_MAGENTA}${BOLD}${WHITE}=== CLUSTER EXPANSION ===${RESET}"
echo "${YELLOW}${BOLD}Creating second cluster...${RESET}"
(gcloud bigtable clusters create ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --zone=$ZONE2 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Second cluster created${RESET}"

echo "${YELLOW}${BOLD}Configuring autoscaling for second cluster...${RESET}"
(gcloud bigtable clusters update ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Second cluster autoscaling configured${RESET}"

echo "${BG_MAGENTA}${BOLD}${WHITE}=== BACKUP OPERATIONS ===${RESET}"
echo "${YELLOW}${BOLD}Creating backup...${RESET}"
(gcloud bigtable backups create PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 \
  --table=PersonalizedProducts \
  --retention-period=7d >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Backup created${RESET}"

echo "${YELLOW}${BOLD}Restoring backup...${RESET}"
(gcloud bigtable instances tables restore \
--source=projects/$DEVSHELL_PROJECT_ID/instances/ecommerce-recommendations/clusters/ecommerce-recommendations-c1/backups/PersonalizedProducts_7 \
--async \
--destination=PersonalizedProducts_7_restored \
--destination-instance=ecommerce-recommendations \
--project=$DEVSHELL_PROJECT_ID >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Backup restore initiated${RESET}"

echo "${YELLOW}${BOLD}Waiting for operations to complete...${RESET}"
progress_bar 0.1

echo "${BG_MAGENTA}${BOLD}${WHITE}=== FINAL DATA IMPORT ===${RESET}"
echo "${YELLOW}${BOLD}Re-importing session data...${RESET}"
(gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Session data re-imported${RESET}"

echo "${YELLOW}${BOLD}Re-importing recommendations data...${RESET}"
(gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Recommendations data re-imported${RESET}"

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}Check The Score${RESET}" "${GREEN}${BOLD}Upto Task 4${RESET}"

echo "${YELLOW}${BOLD}Final cleanup operations...${RESET}"
progress_bar 0.05

echo "${YELLOW}${BOLD}Deleting backup...${RESET}"
(gcloud bigtable backups delete PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 --quiet >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Backup deleted${RESET}"

echo "${YELLOW}${BOLD}Deleting Bigtable instance...${RESET}"
(gcloud bigtable instances delete ecommerce-recommendations --quiet >/dev/null 2>&1) & spinner
echo "${GREEN}${BOLD}✓ Bigtable instance deleted${RESET}"

# Final message
echo
echo "${BG_RED}${BOLD}${WHITE}============================================${RESET}"
echo "${BG_RED}${BOLD}${WHITE}  Congratulations For Completing The Lab!  ${RESET}"
echo "${BG_RED}${BOLD}${WHITE}============================================${RESET}"
echo
echo "${CYAN}${BOLD}Don't forget to subscribe to my channel:${RESET}"
echo "${YELLOW}${BOLD}https://www.youtube.com/@drabhishek.5460${RESET}"
echo

#-----------------------------------------------------end----------------------------------------------------------#
