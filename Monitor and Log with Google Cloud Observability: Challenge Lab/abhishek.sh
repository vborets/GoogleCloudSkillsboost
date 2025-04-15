#!/bin/bash

# Enhanced Color Definitions
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

BG_BLACK=$'\033[40m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'

BOLD=$'\033[1m'
RESET=$'\033[0m'
UNDERLINE=$'\033[4m'

# Header Section
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}        WELCOME TO DR ABHISHEK CLOUD TUTORIALS            ${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}⚡ Initializing Video Queue Monitoring Configuration...${RESET}"
echo

# Step 1: Enable Monitoring API
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ API ENABLEMENT ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Enabling Monitoring API...${RESET}"
gcloud services enable monitoring.googleapis.com
echo "${GREEN}✅ Monitoring API enabled successfully!${RESET}"
echo

# Step 2: Instance Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬ INSTANCE CONFIGURATION ▬▬▬▬▬${RESET}"
echo "${YELLOW}Retrieving instance details...${RESET}"
export ZONE=$(gcloud compute instances list video-queue-monitor --format 'csv[no-heading](zone)')
export REGION="${ZONE%-*}"
export INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --format="get(id)")
echo "${CYAN}Instance Zone: ${WHITE}${BOLD}$ZONE${RESET}"
echo "${CYAN}Region: ${WHITE}${BOLD}$REGION${RESET}"
echo "${CYAN}Instance ID: ${WHITE}${BOLD}$INSTANCE_ID${RESET}"
echo

# Step 3: Instance Management
echo "${GREEN}${BOLD}▬▬▬▬▬ INSTANCE MANAGEMENT ▬▬▬▬▬${RESET}"
echo "${YELLOW}Stopping video-queue-monitor instance...${RESET}"
gcloud compute instances stop video-queue-monitor --zone $ZONE
echo "${GREEN}✅ Instance stopped successfully!${RESET}"
echo

# Step 4: Startup Script Creation
echo "${GREEN}${BOLD}▬▬▬▬▬ STARTUP SCRIPT SETUP ▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating startup script...${RESET}"
cat > startup-script.sh <<'EOF_START'
#!/bin/bash

# Environment Setup
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Install Dependencies
sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

# Setup Go Environment
mkdir -p /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

# Install Application Code
mkdir -p /work/go/video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

# Get Dependencies
go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

# Configure Environment
export MY_PROJECT_ID=$DEVSHELL_PROJECT_ID
export MY_GCE_INSTANCE_ID=$INSTANCE_ID
export MY_GCE_INSTANCE_ZONE=$ZONE

# Initialize and Run Application
cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_START

echo "${GREEN}✅ Startup script created successfully!${RESET}"
echo

# Step 5: Apply Startup Script
echo "${GREEN}${BOLD}▬▬▬▬▬ SCRIPT DEPLOYMENT ▬▬▬▬▬${RESET}"
echo "${YELLOW}Applying startup script to instance...${RESET}"
gcloud compute instances add-metadata video-queue-monitor \
  --zone $ZONE \
  --metadata-from-file startup-script=startup-script.sh
echo "${GREEN}✅ Startup script applied successfully!${RESET}"
echo

# Step 6: Start Instance
echo "${GREEN}${BOLD}▬▬▬▬▬ INSTANCE STARTUP ▬▬▬▬▬${RESET}"
echo "${YELLOW}Starting video-queue-monitor instance...${RESET}"
gcloud compute instances start video-queue-monitor --zone $ZONE
echo "${GREEN}✅ Instance started successfully!${RESET}"
echo

# Step 7: Monitoring Setup
echo "${GREEN}${BOLD}▬▬▬▬▬ MONITORING CONFIGURATION ▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating logging metric for high resolution videos...${RESET}"
gcloud logging metrics create $METRIC \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=("file_format=4K" OR "file_format=8K")'
echo "${GREEN}✅ Logging metric created successfully!${RESET}"
echo

# Step 8: Notification Channel
echo "${GREEN}${BOLD}▬▬▬▬▬ NOTIFICATION SETUP ▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating email notification channel...${RESET}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "video-queue-alerts",
  "description": "Video Queue Monitoring Alerts",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"
echo "${GREEN}✅ Notification channel created successfully!${RESET}"
echo

# Step 9: Alert Policy
echo "${GREEN}${BOLD}▬▬▬▬▬ ALERT POLICY SETUP ▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating alert policy...${RESET}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > video-queue-alert.json <<EOF_END
{
  "displayName": "video-queue-alerts",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "High Resolution Video Upload Rate",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$METRIC\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": $VALUE
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file=video-queue-alert.json
echo "${GREEN}✅ Alert policy created successfully!${RESET}"
echo

# Completion Section
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}          LAB COMPLETED SUCCESSFULLY!                  ${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}📊 Monitoring Dashboard:${RESET}"
echo "${BLUE}${UNDERLINE}https://console.cloud.google.com/monitoring/dashboards?project=$DEVSHELL_PROJECT_ID${RESET}"
echo
echo "${MAGENTA}${BOLD}For more cloud engineering tutorials, visit:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${GREEN}${BOLD}Happy cloud monitoring!${RESET}"
