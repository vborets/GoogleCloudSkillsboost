#!/bin/bash

set -euo pipefail

# Color Definitions
BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
RESET=$(tput sgr0)

# Function to show spinner while commands run
spinner() {
    local pid=$!
    local delay=0.25
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

# Welcome message
echo "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}          Welcome to Dr. Abhishek's Cloud Tutorials!           ${RESET}"
echo "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${BLUE}${BOLD}    Network Connectivity Center (NCC) Setup Script             ${RESET}"
echo "${YELLOW}For more GCP tutorials, visit: https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${GREEN}${BOLD}Starting deployment...${RESET}"
echo

PROJECT_ID=$(gcloud config get-value project)
HUB_NAME=ncc-hub

echo -n "Detecting region from existing VPN tunnels... "
REGION=$(gcloud compute vpn-tunnels list --format="value(region)" --limit=1) &
spinner

if [[ -z "$REGION" ]]; then
  echo "${RED}❌ Unable to detect region from VPN tunnels.${RESET}"
  exit 1
fi

echo "${GREEN}✅ Region detected: $REGION${RESET}"

# Create NCC Hub (location global)
if gcloud network-connectivity hubs describe $HUB_NAME --project=$PROJECT_ID >/dev/null 2>&1; then
  echo "${YELLOW}Hub $HUB_NAME already exists, skipping creation.${RESET}"
else
  echo -n "🚀 Creating NCC hub $HUB_NAME... "
  gcloud network-connectivity hubs create $HUB_NAME \
    --project=$PROJECT_ID \
    --description="Global NCC Hub" > /dev/null 2>&1 &
  spinner
  echo "${GREEN}Done${RESET}"
fi

# Gather VPN tunnels for On-Prem Offices
echo -n "Gathering VPN tunnels for On-Prem Offices... "
OFFICE1_TUNNELS=$(gcloud compute vpn-tunnels list --filter="name~'office1'" --format="value(name)") &
OFFICE2_TUNNELS=$(gcloud compute vpn-tunnels list --filter="name~'office2'" --format="value(name)") &
spinner

if [[ -z "$OFFICE1_TUNNELS" ]]; then
  echo "${RED}❌ No Office 1 VPN tunnels found!${RESET}"
  exit 1
fi

if [[ -z "$OFFICE2_TUNNELS" ]]; then
  echo "${RED}❌ No Office 2 VPN tunnels found!${RESET}"
  exit 1
fi

echo "${GREEN}✅ Found Office 1 tunnels: $(echo "$OFFICE1_TUNNELS" | wc -l)${RESET}"
echo "${GREEN}✅ Found Office 2 tunnels: $(echo "$OFFICE2_TUNNELS" | wc -l)${RESET}"

# Task 1: Connect two On-Prem VPCs using NCC (VPN spokes)
echo
echo "${BOLD}${RED}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${RED}        Connecting On-Prem VPCs using NCC Spokes         ${RESET}"
echo "${BOLD}${RED}╚════════════════════════════════════════════════════════╝${RESET}"
echo

echo -n "🔧 Creating spokes for On-Prem Office 1 VPN tunnels... "
i=1
while read -r tunnel_name; do
  tunnel_full="projects/$PROJECT_ID/regions/$REGION/vpnTunnels/$tunnel_name"
  spoke_name="office-1-spoke-$i"
  
  gcloud alpha network-connectivity spokes create $spoke_name \
    --project=$PROJECT_ID \
    --hub=$HUB_NAME \
    --region=$REGION \
    --vpn-tunnel=$tunnel_full \
    --description="Spoke for On-Prem Office 1 tunnel $i" > /dev/null 2>&1 || echo "${YELLOW}⚠️ $spoke_name may already exist.${RESET}"

  ((i++))
done <<< "$OFFICE1_TUNNELS" &
spinner
echo "${GREEN}Done${RESET}"

echo -n "🔧 Creating spokes for On-Prem Office 2 VPN tunnels... "
i=1
while read -r tunnel_name; do
  tunnel_full="projects/$PROJECT_ID/regions/$REGION/vpnTunnels/$tunnel_name"
  spoke_name="office-2-spoke-$i"
  
  gcloud alpha network-connectivity spokes create $spoke_name \
    --project=$PROJECT_ID \
    --hub=$HUB_NAME \
    --region=$REGION \
    --vpn-tunnel=$tunnel_full \
    --description="Spoke for On-Prem Office 2 tunnel $i" > /dev/null 2>&1 || echo "${YELLOW}⚠️ $spoke_name may already exist.${RESET}"

  ((i++))
done <<< "$OFFICE2_TUNNELS" &
spinner
echo "${GREEN}Done${RESET}"

WORKLOAD_VPC1="workload-vpc-1"
WORKLOAD_VPC2="workload-vpc-2"

echo
echo "${BOLD}${RED}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${RED}            Creating Workload VPC Spokes                 ${RESET}"
echo "${BOLD}${RED}╚════════════════════════════════════════════════════════╝${RESET}"
echo

echo -n "🔧 Creating workload VPC spokes... "
gcloud network-connectivity spokes linked-vpc-network create workload-1-spoke \
  --project=$PROJECT_ID \
  --hub=$HUB_NAME \
  --vpc-network=$WORKLOAD_VPC1 \
  --global \
  --description="Spoke for Workload VPC 1" > /dev/null 2>&1 || echo "${YELLOW}⚠️ workload-1-spoke may already exist.${RESET}"

gcloud network-connectivity spokes linked-vpc-network create workload-2-spoke \
  --project=$PROJECT_ID \
  --hub=$HUB_NAME \
  --vpc-network=$WORKLOAD_VPC2 \
  --global \
  --description="Spoke for Workload VPC 2" > /dev/null 2>&1 || echo "${YELLOW}⚠️ workload-2-spoke may already exist.${RESET}" &
spinner
echo "${GREEN}Done${RESET}"

echo
echo "${BOLD}${RED}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${RED}            Creating Hybrid Spokes                       ${RESET}"
echo "${BOLD}${RED}╚════════════════════════════════════════════════════════╝${RESET}"
echo

echo -n "🔧 Creating hybrid spokes for On-Prem Office 1 VPN tunnels... "
i=1
while read -r tunnel_name; do
  tunnel_full="projects/$PROJECT_ID/regions/$REGION/vpnTunnels/$tunnel_name"
  spoke_name="hybrid-office-1-spoke-$i"
  
  gcloud alpha network-connectivity spokes create $spoke_name \
    --project=$PROJECT_ID \
    --hub=$HUB_NAME \
    --region=$REGION \
    --vpn-tunnel=$tunnel_full \
    --description="Hybrid spoke for On-Prem Office 1 tunnel $i" > /dev/null 2>&1 || echo "${YELLOW}⚠️ $spoke_name may already exist.${RESET}"

  ((i++))
done <<< "$OFFICE1_TUNNELS" &
spinner
echo "${GREEN}Done${RESET}"

echo
echo "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}               NCC SETUP COMPLETED SUCCESSFULLY!               ${RESET}"
echo "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo "${GREEN}✅ NCC Hub: $HUB_NAME${RESET}"
echo "${GREEN}✅ Region: $REGION${RESET}"
echo "${GREEN}✅ Office 1 Spokes: $(echo "$OFFICE1_TUNNELS" | wc -l) created${RESET}"
echo "${GREEN}✅ Office 2 Spokes: $(echo "$OFFICE2_TUNNELS" | wc -l) created${RESET}"
echo "${GREEN}✅ Workload VPC Spokes: 2 created${RESET}"
echo "${GREEN}✅ Hybrid Spokes: $(echo "$OFFICE1_TUNNELS" | wc -l) created${RESET}"
echo
echo "${BOLD}${MAGENTA}Thank you for following along with Dr. Abhishek's${RESET}"
echo "${BOLD}${MAGENTA}Cloud Tutorial! Don't forget to like the video${RESET}"
echo "${BOLD}${MAGENTA}and subscribe to the channel for more content!${RESET}"
echo "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}        YouTube: https://www.youtube.com/@drabhishek.5460       ${RESET}"
echo "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
