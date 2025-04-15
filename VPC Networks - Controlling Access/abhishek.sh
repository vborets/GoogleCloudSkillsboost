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

NO_COLOR=$'\033[0m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'

# Header Section
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}        WELCOME TO DR ABHISHEK CLOUD TUTORIAL              ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${MAGENTA}${BOLD}          Expert Tutorial by Dr. Abhishek              ${RESET}"
echo "${YELLOW}For more GCP tutorials, visit: ${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${BLUE}${BOLD}⚡ Initializing Load Balancer Configuration...${RESET}"
echo

# User Input Section
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ INPUT PARAMETERS ▬▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}${BOLD}Enter ZONE (e.g., us-central1-a): ${RESET}" ZONE
read -p "${YELLOW}${BOLD}Enter your Project ID: ${RESET}" DEVSHELL_PROJECT_ID

echo
echo "${CYAN}Configuration Parameters:${RESET}"
echo "${WHITE}Zone: ${BOLD}$ZONE${RESET}"
echo "${WHITE}Project ID: ${BOLD}$DEVSHELL_PROJECT_ID${RESET}"
echo

# Instance Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ INSTANCE CREATION ▬▬▬▬▬▬▬▬▬${RESET}"

echo "${YELLOW}Creating blue instance...${RESET}"
gcloud compute instances create blue \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --tags=web-server,http-server \
  --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "${GREEN}✅ Blue instance created!${RESET}"

echo "${YELLOW}Creating green instance...${RESET}"
gcloud compute instances create green \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "${GREEN}✅ Green instance created!${RESET}"

echo "${YELLOW}Creating test-vm instance...${RESET}"
gcloud compute instances create test-vm \
  --machine-type=f1-micro \
  --subnet=default \
  --zone=$ZONE
echo "${GREEN}✅ Test VM created!${RESET}"
echo

# Firewall Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FIREWALL SETUP ▬▬▬▬▬▬▬▬▬${RESET}"

echo "${YELLOW}Creating firewall rule for web servers...${RESET}"
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-http-web-server \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80,icmp \
  --source-ranges=0.0.0.0/0 \
  --target-tags=web-server
echo "${GREEN}✅ Firewall rule created!${RESET}"
echo

# IAM Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ IAM CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"

echo "${YELLOW}Creating network-admin service account...${RESET}"
gcloud iam service-accounts create network-admin \
  --description="Service account for Network Admin role" \
  --display-name="Network-admin"
echo "${GREEN}✅ Service account created!${RESET}"

echo "${YELLOW}Assigning Network Admin role...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.networkAdmin
echo "${GREEN}✅ Role assigned!${RESET}"

echo "${YELLOW}Creating service account key...${RESET}"
gcloud iam service-accounts keys create credentials.json \
  --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com
echo "${GREEN}✅ Service account key created!${RESET}"
echo

# Web Server Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ WEB SERVER SETUP ▬▬▬▬▬▬▬▬▬${RESET}"

echo "${YELLOW}Preparing blue server configuration script...${RESET}"
cat > bluessh.sh <<'EOF_END'
#!/bin/bash
sudo apt-get update
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the blue server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END
echo "${GREEN}✅ Blue server script prepared!${RESET}"

echo "${YELLOW}Transferring script to blue instance...${RESET}"
gcloud compute scp bluessh.sh blue:/tmp \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet
echo "${GREEN}✅ Script transferred!${RESET}"

echo "${YELLOW}Executing configuration on blue instance...${RESET}"
gcloud compute ssh blue \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="bash /tmp/bluessh.sh" \
  --ssh-flag="-o ConnectTimeout=60"
echo "${GREEN}✅ Blue server configured!${RESET}"
echo

echo "${YELLOW}Preparing green server configuration script...${RESET}"
cat > greenssh.sh <<'EOF_END'
#!/bin/bash
sudo apt-get update
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the green server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END
echo "${GREEN}✅ Green server script prepared!${RESET}"

echo "${YELLOW}Transferring script to green instance...${RESET}"
gcloud compute scp greenssh.sh green:/tmp \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet
echo "${GREEN}✅ Script transferred!${RESET}"

echo "${YELLOW}Executing configuration on green instance...${RESET}"
gcloud compute ssh green \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="bash /tmp/greenssh.sh"
echo "${GREEN}✅ Green server configured!${RESET}"
echo

# Completion Message
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}          LAB COMPLETED!                 ${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}🙏 Special thanks to Dr. Abhishek for this tutorial!${RESET}"
echo "${YELLOW}${BOLD}📺 Subscribe for more GCP content:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${MAGENTA}${BOLD}🚀 Your blue-green deployment is ready for testing!${RESET}"
