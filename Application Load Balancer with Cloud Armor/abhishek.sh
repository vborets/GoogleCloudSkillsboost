#!/bin/bash

# Modern Color Palette
DARK_BLUE=$(tput setaf 27)
TEAL=$(tput setaf 50)
PURPLE=$(tput setaf 129)
ORANGE=$(tput setaf 208)
LIME=$(tput setaf 118)
PINK=$(tput setaf 200)
RED=$(tput setaf 196)
YELLOW=$(tput setaf 3)
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
echo "${DARK_BLUE}${BOLD}╔════════════════════════════════════════════════════╗"
echo "       WELCOME TO DR ABHISHEK CLOUD  TUTORIALS      "
echo "╚════════════════════════════════════════════════════╝${RESET}"
echo

# Set project ID
export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
echo "${LIME}${BOLD}✔ Project ID: ${TEAL}$DEVSHELL_PROJECT_ID${RESET}"
echo

# Step 1: Create Load Balancer Configuration
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 1: LOAD BALANCER CONFIGURATION ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo

# Set load balancer name
LB_NAME="http-lb"
echo "${LIME}${BOLD}✔ Load Balancer Name: ${TEAL}$LB_NAME${RESET}"

# Create backend service
echo -n "${TEAL}${BOLD}⚖️ Creating backend service..."
BACKEND_SERVICE_NAME="${LB_NAME}-backend-service"
gcloud compute backend-services create $BACKEND_SERVICE_NAME \
    --protocol=HTTP \
    --port-name=http \
    --global \
    --enable-cdn \
    --connection-draining-timeout=300 > /dev/null 2>&1 &
spinner
echo -e "\r${LIME}${BOLD}✔ Backend service created: ${TEAL}$BACKEND_SERVICE_NAME          ${RESET}"

# Create URL map
echo -n "${TEAL}${BOLD}🗺️ Creating URL map..."
URL_MAP_NAME="${LB_NAME}-url-map"
gcloud compute url-maps create $URL_MAP_NAME \
    --default-service $BACKEND_SERVICE_NAME > /dev/null 2>&1 &
spinner
echo -e "\r${LIME}${BOLD}✔ URL map created: ${TEAL}$URL_MAP_NAME          ${RESET}"

# Create target HTTP proxy
echo -n "${TEAL}${BOLD}🎯 Creating target HTTP proxy..."
TARGET_PROXY_NAME="${LB_NAME}-target-proxy"
gcloud compute target-http-proxies create $TARGET_PROXY_NAME \
    --url-map $URL_MAP_NAME > /dev/null 2>&1 &
spinner
echo -e "\r${LIME}${BOLD}✔ Target HTTP proxy created: ${TEAL}$TARGET_PROXY_NAME          ${RESET}"

# Create forwarding rule (IPv4)
echo -n "${TEAL}${BOLD}🚦 Creating IPv4 forwarding rule..."
gcloud compute forwarding-rules create ${LB_NAME}-forwarding-rule \
    --global \
    --target-http-proxy=$TARGET_PROXY_NAME \
    --ports=80 \
    --network-tier=PREMIUM > /dev/null 2>&1 &
spinner
echo -e "\r${LIME}${BOLD}✔ IPv4 forwarding rule created          ${RESET}"

# Create forwarding rule (IPv6)
echo -n "${TEAL}${BOLD}🚦 Creating IPv6 forwarding rule..."
gcloud compute forwarding-rules create ${LB_NAME}-forwarding-rule-ipv6 \
    --global \
    --target-http-proxy=$TARGET_PROXY_NAME \
    --ports=80 \
    --ip-version=IPV6 \
    --network-tier=PREMIUM > /dev/null 2>&1 &
spinner
echo -e "\r${LIME}${BOLD}✔ IPv6 forwarding rule created          ${RESET}"

# Get Load Balancer IP
echo -n "${TEAL}${BOLD}🔍 Retrieving Load Balancer IP..."
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe ${LB_NAME}-forwarding-rule --global --format="value(IPAddress)")
echo -e "\r${LIME}${BOLD}✔ Load Balancer IP: ${TEAL}$LB_IP_ADDRESS          ${RESET}"

# Completion Message
echo
echo "${DARK_BLUE}${BOLD}╔════════════════════════════════════════════════════╗"
echo "       GLOBAL HTTP(S) LOAD BALANCER CREATION COMPLETE!      "
echo "╚════════════════════════════════════════════════════╝${RESET}"
echo
echo "${LIME}${BOLD}✔ Load Balancer Name: ${TEAL}$LB_NAME${RESET}"
echo "${LIME}${BOLD}✔ Load Balancer IP: ${TEAL}$LB_IP_ADDRESS${RESET}"
echo "${LIME}${BOLD}✔ Backend Service: ${TEAL}$BACKEND_SERVICE_NAME${RESET}"
echo "${LIME}${BOLD}✔ URL Map: ${TEAL}$URL_MAP_NAME${RESET}"
echo "${LIME}${BOLD}✔ Target HTTP Proxy: ${TEAL}$TARGET_PROXY_NAME${RESET}"
echo
echo "${YELLOW}${BOLD}Next steps:"
echo "1. Add backend services and instance groups to your load balancer"
echo "2. Configure health checks for your backends"
echo "3. Set up any additional routing rules as needed"
echo
echo "${PURPLE}${BOLD}For more cloud engineering tutorials, visit:"
echo "${TEAL}https://www.youtube.com/@drabhishek.5460/${RESET}"
echo
