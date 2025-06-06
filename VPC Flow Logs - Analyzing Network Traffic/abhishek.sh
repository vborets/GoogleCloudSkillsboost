#!/bin/bash
# Colors for output formatting
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome Banner
echo
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   DR. ABHISHEK CLOUD INFRASTRUCTURE SETUP   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===============================================${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}${BOLD_TEXT}📺 YouTube Channel: https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}👍 Please subscribe for more cloud tutorials!${RESET_FORMAT}"
echo

# Set region from zone
export REGION="${ZONE%-*}"

echo "${GREEN_TEXT}${BOLD_TEXT}🛠️ Creating VPC Network...${RESET_FORMAT}"
gcloud compute networks create vpc-net \
    --project=$DEVSHELL_PROJECT_ID \
    --description="Cloud Infrastructure by Dr. Abhishek" \
    --subnet-mode=custom

echo "${GREEN_TEXT}${BOLD_TEXT}🌐 Creating Subnet with Flow Logs...${RESET_FORMAT}"
gcloud compute networks subnets create vpc-subnet \
    --project=$DEVSHELL_PROJECT_ID \
    --network=vpc-net \
    --region=$REGION \
    --range=10.1.3.0/24 \
    --enable-flow-logs

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for network resources to provision...${RESET_FORMAT}"
sleep 30

echo "${GREEN_TEXT}${BOLD_TEXT}🔥 Configuring Firewall Rules...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http-ssh \
    --project=$DEVSHELL_PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=vpc-net \
    --action=ALLOW \
    --rules=tcp:80,tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP/SSH access - Dr. Abhishek Cloud Lab"

echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Launching Web Server Instance...${RESET_FORMAT}"
gcloud compute instances create web-server \
    --zone=$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --machine-type=e2-micro \
    --subnet=vpc-subnet \
    --network=vpc-net \
    --tags=http-server \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
        echo "Installing Apache - Dr. Abhishek Cloud Lab"
        sudo apt update
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo systemctl enable apache2
        echo "<html><body><h1>Welcome to Dr. Abhishek Cloud Lab</h1></body></html>" | sudo tee /var/www/html/index.html' \
    --labels=owner=dr-abhishek,environment=lab

echo "${GREEN_TEXT}${BOLD_TEXT}🔒 Creating Additional HTTP Firewall Rule...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http \
    --project=$DEVSHELL_PROJECT_ID \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP traffic - Dr. Abhishek Cloud Lab"

echo "${GREEN_TEXT}${BOLD_TEXT}📊 Creating BigQuery Dataset for Flow Logs...${RESET_FORMAT}"
bq --project_id=$DEVSHELL_PROJECT_ID mk bq_vpcflows

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for instance to become ready...${RESET_FORMAT}"
sleep 60

# Get server IP and generate traffic
CP_IP=$(gcloud compute instances describe web-server \
    --zone=$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

export MY_SERVER=$CP_IP

echo "${GREEN_TEXT}${BOLD_TEXT}📡 Generating Test Traffic to Server ($MY_SERVER)...${RESET_FORMAT}"
for ((i=1;i<=20;i++)); do
    echo "${DIM_TEXT}Request $i: $(curl -s $MY_SERVER)${RESET_FORMAT}"
    sleep 1
done

# Output useful links
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Useful Links:${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}Firewall Policy: https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-http-ssh?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}VPC Flow Logs: https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_subnetwork%22%0Alog_name%3D%22projects%2F$DEVSHELL_PROJECT_ID%2Flogs%2Fcompute.googleapis.com%252Fvpc_flows%22;cursorTimestamp=2024-06-03T07:20:00.734122029Z;duration=PT1H?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}VM Instance: https://console.cloud.google.com/compute/instancesDetail/zones/$ZONE/instances/web-server?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🎉 Infrastructure Deployment Complete!${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}💖 Don't forget to subscribe to Dr. Abhishek's YouTube channel:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo
