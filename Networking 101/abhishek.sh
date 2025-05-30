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

# Function to display section headers
section_header() {
    echo
    echo "${BG_BLUE}${BOLD}${WHITE}╔════════════════════════════════════════════════════════╗${RESET}"
    echo "${BG_BLUE}${BOLD}${WHITE}  Welcome To Dr Abhishek Cloud Tutorials $1${RESET}"
    echo "${BG_BLUE}${BOLD}${WHITE}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# Function to show progress spinner
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

# Welcome message
clear
section_header "Dr. Abhishek's Network Lab Setup"
echo "${GREEN}${BOLD}Now We will configure a custom GCP network environment${RESET}"
echo "${CYAN}For more cloud tutorials, visit: https://www.youtube.com/@drabhishek.5460${RESET}"
echo

# Start execution
echo "${BG_MAGENTA}${BOLD}Starting Network Configuration${RESET}"


gcloud compute networks create taw-custom-network --subnet-mode custom

gcloud compute networks subnets create subnet-$REGION_1 \
   --network taw-custom-network \
   --region $REGION_1 \
   --range 10.0.0.0/16

gcloud compute networks subnets create subnet-$REGION_2 \
   --network taw-custom-network \
   --region $REGION_2 \
   --range 10.1.0.0/16

gcloud compute networks subnets create subnet-$REGION_3 \
   --network taw-custom-network \
   --region $REGION_3 \
   --range 10.2.0.0/16


gcloud compute firewall-rules create nw101-allow-http \
--allow tcp:80 --network taw-custom-network --source-ranges 0.0.0.0/0 \
--target-tags http

gcloud compute firewall-rules create "nw101-allow-icmp" --allow icmp --network "taw-custom-network" --target-tags rules

gcloud compute firewall-rules create "nw101-allow-internal" --allow tcp:0-65535,udp:0-65535,icmp --network "taw-custom-network" --source-ranges "10.0.0.0/16","10.2.0.0/16","10.1.0.0/16"

gcloud compute firewall-rules create "nw101-allow-ssh" --allow tcp:22 --network "taw-custom-network" --target-tags "ssh"

gcloud compute firewall-rules create "nw101-allow-rdp" --allow tcp:3389 --network "taw-custom-network"
# Completion message
section_header "Lab Completed Successfully!"
echo "${BG_GREEN}${BOLD}${BLACK}Congratulations on completing Dr. Abhishek's Network Lab!${RESET}"
echo
echo "${MAGENTA}${BOLD}For more cloud computing tutorials and labs:${RESET}"
echo "${CYAN}${BOLD}Subscribe to Dr. Abhishek's YouTube channel:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
