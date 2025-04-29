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

clear

# Dr. Abhishek Banner
echo "${BLUE}${BOLD}====================================================================${RESET}"
echo "${BLUE}${BOLD}                  Dr. Abhishek Cloud Tutorials                     ${RESET}"
echo "${BLUE}${BOLD}====================================================================${RESET}"
echo
echo "${GREEN}${BOLD}Starting Security Command Center Lab Execution${RESET}"
echo

# Step 1: Get Project ID
echo "${CYAN}${BOLD}➤ Getting Project ID, Zone & Region${RESET}"
export PROJECT_ID=$(gcloud config get project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

echo "${GREEN}✓ Project: $PROJECT_ID | Region: $REGION | Zone: $ZONE${RESET}"

# Step 2: Create Pub/Sub Topic
echo "${CYAN}${BOLD}➤ Creating Pub/Sub Topic${RESET}"
(gcloud pubsub topics create projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created Pub/Sub topic: export-findings-pubsub-topic${RESET}"

# Step 3: Create Pub/Sub Subscription
echo "${CYAN}${BOLD}➤ Creating Pub/Sub Subscription${RESET}"
(gcloud pubsub subscriptions create export-findings-pubsub-topic-sub --topic=projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created subscription: export-findings-pubsub-topic-sub${RESET}"

# Step 4: Manual Step
echo "${CYAN}${BOLD}➤ Manual Configuration Required${RESET}"
echo "${YELLOW}Please open this URL to create export-findings-pubsub:${RESET}"
echo "${BLUE}https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=$DEVSHELL_PROJECT_ID${RESET}"

# Progress check function
function check_progress {
    while true; do
        echo
        read -p "${YELLOW}${BOLD}Have you created export-findings-pubsub? (Y/N): ${RESET}" user_input
        case "$user_input" in
            [Yy]) 
                echo "${GREEN}✓ Continuing with the lab...${RESET}"
                break
                ;;
            [Nn]) 
                echo "${RED}Please create export-findings-pubsub first.${RESET}"
                ;;
            *) 
                echo "${MAGENTA}Invalid input. Please enter Y or N.${RESET}" 
                ;;
        esac
    done
}

check_progress

# Step 5: Create Compute Instance
echo "${CYAN}${BOLD}➤ Creating Compute Instance${RESET}"
(gcloud compute instances create instance-1 --zone=$ZONE --machine-type e2-micro --scopes=https://www.googleapis.com/auth/cloud-platform > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created instance: instance-1${RESET}"

# Step 6: Create BigQuery Dataset
echo "${CYAN}${BOLD}➤ Creating BigQuery Dataset${RESET}"
(bq --location=$REGION --apilog=/dev/null mk --dataset $PROJECT_ID:continuous_export_dataset > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created dataset: continuous_export_dataset${RESET}"

# Step 7: Enable Security Center API
echo "${CYAN}${BOLD}➤ Enabling Security Center API${RESET}"
(gcloud services enable securitycenter.googleapis.com --quiet > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Security Center API enabled${RESET}"

# Step 8: Create SCC BigQuery Export
echo "${CYAN}${BOLD}➤ Creating SCC BigQuery Export${RESET}"
(gcloud scc bqexports create scc-bq-cont-export --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset --project=$PROJECT_ID --quiet > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created SCC BigQuery export${RESET}"

# Step 9: Create Service Accounts and Keys
echo "${CYAN}${BOLD}➤ Creating Service Accounts${RESET}"
for i in {0..2}; do
    (gcloud iam service-accounts create sccp-test-sa-$i > /dev/null 2>&1) &
    spinner
    (gcloud iam service-accounts keys create /tmp/sa-key-$i.json --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com > /dev/null 2>&1) &
    spinner
    echo "${GREEN}✓ Created service account: sccp-test-sa-$i${RESET}"
done

# Wait for findings function
function wait_for_findings() {
    echo "${CYAN}${BOLD}➤ Waiting for findings to populate...${RESET}"
    while true; do
        result=$(bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
          "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings" 2>/dev/null)
        
        if echo "$result" | grep -qE '^[|] [a-f0-9]{32} '; then
            echo "${GREEN}✓ Findings detected!${RESET}"
            break
        else
            printf "${YELLOW}⏳ No findings yet. Checking again in 30 seconds...${RESET}\r"
            sleep 30
        fi
    done
}

wait_for_findings

# Step 10: Create Storage Bucket
echo "${CYAN}${BOLD}➤ Creating Storage Bucket${RESET}"
(gsutil mb -l $REGION gs://$BUCKET_NAME/ > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Created bucket: gs://$BUCKET_NAME/${RESET}"

# Step 11: Enforce Public Access Prevention
echo "${CYAN}${BOLD}➤ Enforcing Public Access Prevention${RESET}"
(gsutil pap set enforced gs://$BUCKET_NAME > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Public access prevention enforced${RESET}"

# Step 12: Export Findings to JSONL
echo "${CYAN}${BOLD}➤ Exporting Findings to JSONL${RESET}"
(gcloud scc findings list "projects/$PROJECT_ID" --format=json | jq -c '.[]' > findings.jsonl) &
spinner
echo "${GREEN}✓ Findings exported to findings.jsonl${RESET}"

# Step 13: Upload JSONL to Bucket
echo "${CYAN}${BOLD}➤ Uploading Findings to Cloud Storage${RESET}"
(gsutil cp findings.jsonl gs://$BUCKET_NAME/ > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Findings uploaded to gs://$BUCKET_NAME/findings.jsonl${RESET}"

# Final Manual Step
echo "${CYAN}${BOLD}➤ Final Manual Step${RESET}"
echo "${YELLOW}Please open BigQuery Console to create old_findings table:${RESET}"
echo "${BLUE}https://console.cloud.google.com/bigquery?project=$DEVSHELL_PROJECT_ID${RESET}"

# Cleanup
echo "${CYAN}${BOLD}➤ Cleaning up temporary files${RESET}"
(rm -f findings.jsonl /tmp/sa-key-*.json > /dev/null 2>&1) &
spinner
echo "${GREEN}✓ Temporary files removed${RESET}"

# Completion Message
echo
echo "${BLUE}${BOLD}====================================================================${RESET}"
echo "${BLUE}${BOLD}               LAB EXECUTION COMPLETED SUCCESSFULLY               ${RESET}"
echo "${BLUE}${BOLD}====================================================================${RESET}"
echo
echo "${GREEN}${BOLD}Thank you for completing the lab!${RESET}"
echo
echo "${YELLOW}For more cloud tutorials and labs, subscribe to:${RESET}"
echo "${CYAN}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
