#!/bin/bash

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

# Function to validate input
validate_input() {
    local input=$1
    local name=$2
    if [[ -z "$input" ]]; then
        echo "${RED}${BOLD}Error: $name cannot be empty${RESET}"
        exit 1
    fi
}

# Clear screen and display header
clear
echo
echo "${BG_MAGENTA}${BOLD} WELCOME TO DR ABHISHEK CLOUD TUTORIALS ${RESET}"
echo

# Set project ID
export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN}${BOLD}✔ Project ID: ${CYAN}$DEVSHELL_PROJECT_ID${RESET}"

# Zone selection
echo
echo "${YELLOW}${BOLD}Please select a zone:${RESET}"
ZONES=$(gcloud compute zones list --format="value(name)")
select ZONE in $ZONES; do
    validate_input "$ZONE" "Zone"
    break
done
export ZONE
echo "${GREEN}${BOLD}✔ Selected Zone: ${CYAN}$ZONE${RESET}"
echo

# Create VMs
echo "${BLUE}${BOLD}▐▓▒▌ STEP 1: CREATING VM INSTANCES ${RESET}"
echo
echo -n "${CYAN}${BOLD}🖥️ Creating blue instance..."
(gcloud compute instances create blue \
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
    --reservation-affinity=any > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Blue instance created!          ${RESET}"

echo -n "${CYAN}${BOLD}🖥️ Creating green instance..."
(gcloud compute instances create green \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --tags=web-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=green,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Green instance created!          ${RESET}"

echo -n "${CYAN}${BOLD}🖥️ Creating test instance..."
(gcloud compute instances create test-vm \
    --machine-type=f1-micro \
    --subnet=default \
    --zone=$ZONE > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Test instance created!          ${RESET}"

# Firewall rule
echo -n "${CYAN}${BOLD}🛡️ Creating firewall rule..."
(gcloud compute firewall-rules create allow-http-web-server \
    --project=$DEVSHELL_PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80,icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=web-server > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Firewall rule created!          ${RESET}"
echo

# Service account setup
echo "${BLUE}${BOLD}▐▓▒▌ STEP 2: SERVICE ACCOUNT SETUP ${RESET}"
echo
echo -n "${CYAN}${BOLD}👤 Creating network admin service account..."
(gcloud iam service-accounts create network-admin \
    --description="Service account for Network Admin role" \
    --display-name="Network-admin" > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Service account created!          ${RESET}"

echo -n "${CYAN}${BOLD}🔑 Assigning network admin role..."
(gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.networkAdmin" > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Role assigned!          ${RESET}"

echo -n "${CYAN}${BOLD}📄 Creating service account key..."
(gcloud iam service-accounts keys create credentials.json \
    --iam-account="network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Key file created: credentials.json          ${RESET}"
echo

# Configure web servers
echo "${BLUE}${BOLD}▐▓▒▌ STEP 3: WEB SERVER CONFIGURATION ${RESET}"
echo
# Blue server configuration
echo -n "${CYAN}${BOLD}🔵 Configuring blue server..."
cat > bluessh.sh <<'EOF_END'
sudo apt-get update && sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the blue server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

(gcloud compute scp bluessh.sh blue:/tmp \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet > /dev/null 2>&1 && \
gcloud compute ssh blue \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="bash /tmp/bluessh.sh" \
    --ssh-flag="-o ConnectTimeout=60" > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Blue server configured!          ${RESET}"

# Green server configuration
echo -n "${CYAN}${BOLD}🟢 Configuring green server..."
cat > greenssh.sh <<'EOF_END'
sudo apt-get update && sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the green server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

(gcloud compute scp greenssh.sh green:/tmp \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet > /dev/null 2>&1 && \
gcloud compute ssh green \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="bash /tmp/greenssh.sh" \
    --ssh-flag="-o ConnectTimeout=60" > /dev/null 2>&1) &
spinner
echo -e "\r${GREEN}${BOLD}✔ Green server configured!          ${RESET}"

# Get instance IPs
BLUE_IP=$(gcloud compute instances describe blue --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
GREEN_IP=$(gcloud compute instances describe green --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Completion Message
echo
echo "${BG_GREEN}${BLACK}${BOLD} BLUE-GREEN DEPLOYMENT SETUP COMPLETE! ${RESET}"
echo
echo "${GREEN}${BOLD}✔ Blue Server IP: ${CYAN}$BLUE_IP${RESET}"
echo "${GREEN}${BOLD}✔ Green Server IP: ${CYAN}$GREEN_IP${RESET}"
echo
echo "${YELLOW}${BOLD}You can now access your servers:"
echo "  Blue server: ${CYAN}http://$BLUE_IP${RESET}"
echo "  Green server: ${CYAN}http://$GREEN_IP${RESET}"
echo
echo "${MAGENTA}${BOLD}For more cloud tutorials, visit:"
echo "${CYAN}https://www.youtube.com/@drabhishek.5460/${RESET}"
echo

# Cleanup
rm -f bluessh.sh greenssh.sh
