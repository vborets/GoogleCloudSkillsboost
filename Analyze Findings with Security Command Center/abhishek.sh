#!/bin/bash

# ==============================================
#  Security Command Center Guide
#  Created by Dr. Abhishek Cloud Tutorials
#  YouTube: https://www.youtube.com/@drabhishek.5460
# ==============================================

# Color definitions
COLOR_RED=$'\033[1;31m'
COLOR_GREEN=$'\033[1;32m'
COLOR_YELLOW=$'\033[1;33m'
COLOR_BLUE=$'\033[1;34m'
COLOR_MAGENTA=$'\033[1;35m'
COLOR_CYAN=$'\033[1;36m'
COLOR_WHITE=$'\033[1;37m'
FORMAT_RESET=$'\033[0m'

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

# Header
clear
echo
echo "${COLOR_BLUE}╔══════════════════════════════════════════╗${FORMAT_RESET}"
echo "${COLOR_BLUE}║   GOOGLE CLOUD SECURITY Lab             ║${FORMAT_RESET}"
echo "${COLOR_BLUE}║        by Dr. Abhishek Cloud           ║${FORMAT_RESET}"
echo "${COLOR_BLUE}╚══════════════════════════════════════════╝${FORMAT_RESET}"
echo

# Initialize environment
echo "${COLOR_CYAN}🔧 Initializing environment...${FORMAT_RESET}"
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE" &
spinner
gcloud config set compute/region "$REGION" &
spinner

echo "${COLOR_GREEN}✓ Environment configured${FORMAT_RESET}"
echo " Project: ${PROJECT_ID}"
echo " Region:  ${REGION}"
echo " Zone:    ${ZONE}"
echo

# Enable Security Command Center
echo "${COLOR_MAGENTA}🛡️ Enabling Security Command Center API...${FORMAT_RESET}"
gcloud services enable securitycenter.googleapis.com --quiet &
spinner
echo "${COLOR_GREEN}✓ Security Command Center API enabled${FORMAT_RESET}"

# Set up Pub/Sub
export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

echo "${COLOR_YELLOW}📨 Creating Pub/Sub topic...${FORMAT_RESET}"
gcloud pubsub topics create projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
spinner

echo "${COLOR_YELLOW}📩 Creating Pub/Sub subscription...${FORMAT_RESET}"
gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
spinner

echo
echo "${COLOR_YELLOW}Please complete the export configuration:${FORMAT_RESET}"
echo "${COLOR_BLUE}https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=${PROJECT_ID}${FORMAT_RESET}"
echo

# Confirmation prompt
while true; do
    read -p "${COLOR_YELLOW}? Do you want to proceed? (Y/n): ${FORMAT_RESET}" confirm
    case "$confirm" in
        [Yy]|"") break ;;
        [Nn]) echo "Operation canceled."; exit 0 ;;
        *) echo "${COLOR_RED}Invalid input. Please enter Y or N.${FORMAT_RESET}" ;;
    esac
done

# Create compute instance
echo "${COLOR_CYAN}🖥️ Creating compute instance...${FORMAT_RESET}"
gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform &
spinner
echo "${COLOR_GREEN}✓ Compute instance created${FORMAT_RESET}"

# Set up BigQuery
echo "${COLOR_MAGENTA}📊 Configuring BigQuery export...${FORMAT_RESET}"
bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset &
spinner

gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet &
spinner
echo "${COLOR_GREEN}✓ BigQuery export configured${FORMAT_RESET}"

# Create service accounts
echo "${COLOR_YELLOW}👥 Creating service accounts...${FORMAT_RESET}"
for i in {0..2}; do
    gcloud iam service-accounts create sccp-test-sa-$i &
    spinner
    gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
      --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com &
    spinner
    echo "${COLOR_GREEN}✓ Service account sccp-test-sa-$i created${FORMAT_RESET}"
done

# Wait for findings
echo "${COLOR_CYAN}🔍 Waiting for security findings...${FORMAT_RESET}"
query_findings() {
  bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}

has_findings() {
  echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
}

while true; do
    result=$(query_findings)
    if has_findings "$result"; then
        echo "${COLOR_GREEN}✓ Findings detected!${FORMAT_RESET}"
        echo "$result"
        break
    else
        echo "${COLOR_YELLOW}No findings yet. Waiting for 100 seconds...${FORMAT_RESET}"
        sleep 100
    fi
done

# Set up Cloud Storage
echo "${COLOR_MAGENTA}📦 Configuring Cloud Storage...${FORMAT_RESET}"
gsutil mb -l $REGION gs://$BUCKET_NAME/ &
spinner
gsutil pap set enforced gs://$BUCKET_NAME &
spinner
echo "${COLOR_GREEN}✓ Cloud Storage bucket created and secured${FORMAT_RESET}"

# Export findings
echo "${COLOR_YELLOW}📤 Exporting findings to Cloud Storage...${FORMAT_RESET}"
gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl &
spinner
gsutil cp findings.jsonl gs://$BUCKET_NAME/ &
spinner
echo "${COLOR_GREEN}✓ Findings exported to Cloud Storage${FORMAT_RESET}"

# Final output
echo
echo "${COLOR_BLUE}╔══════════════════════════════════════════╗${FORMAT_RESET}"
echo "${COLOR_BLUE}║         SETUP COMPLETED!                ║${FORMAT_RESET}"
echo "${COLOR_BLUE}╚══════════════════════════════════════════╝${FORMAT_RESET}"
echo
echo "${COLOR_WHITE}Next steps:${FORMAT_RESET}"
echo " • View findings in BigQuery:"
echo "   ${COLOR_BLUE}https://console.cloud.google.com/bigquery?project=${PROJECT_ID}${FORMAT_RESET}"
echo
echo "${COLOR_MAGENTA}For more cloud security tutorials, subscribe to:${FORMAT_RESET}"
echo "${COLOR_BLUE}https://www.youtube.com/@drabhishek.5460${FORMAT_RESET}"
echo
