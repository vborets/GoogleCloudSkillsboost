#!/bin/bash

# Enhanced Color Definitions
YELLOW=$'\033[1;33m'
MAGENTA=$'\033[1;35m'
GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
BLUE=$'\033[1;34m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
RESET=$'\033[0m'

# Function to display section header
section_header() {
    echo
    echo "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo "${CYAN}   $1${RESET}"
    echo "${CYAN}╚════════════════════════════════════════════╝${RESET}"
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

clear

# Welcome message
section_header "WELCOME TO DR. ABHISHEK'S CLOUD TUTORIALS"
echo "${MAGENTA}Welcome to Cloud Run Deployment Lab by Dr. Abhishek${RESET}"
echo "${CYAN}YouTube Channel: https://www.youtube.com/@drabhishek.5460${RESET}"
echo "${CYAN}Video Tutorials: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Get region input
echo "${YELLOW}Please enter your preferred region (e.g., us-central1):${RESET}"
read REGION
echo "${GREEN}✓ Region set to: ${REGION}${RESET}"
echo "${CYAN}For more tutorials, subscribe: https://www.youtube.com/@drabhishek.5460${RESET}"
echo

# Enable services
section_header "SERVICE ENABLEMENT"
echo "${BLUE}Enabling required Google Cloud services...${RESET}"
(gcloud services enable run.googleapis.com cloudbuild.googleapis.com > /dev/null 2>&1) & spinner
echo -e "\r${GREEN}✓ Cloud Run and Cloud Build APIs enabled${RESET}"
echo "${CYAN}More tutorials at: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Set project
section_header "PROJECT CONFIGURATION"
echo "${BLUE}Setting active Google Cloud project...${RESET}"
PROJECT_ID=$(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID
echo -e "\r${GREEN}✓ Project set to: ${PROJECT_ID}${RESET}"
echo "${CYAN}Subscribe for more: https://www.youtube.com/@drabhishek.5460${RESET}"
echo

# Clone repository
section_header "CODE SETUP"
echo "${BLUE}Cloning pet-theory repository...${RESET}"
(git clone https://github.com/rosera/pet-theory.git > /dev/null 2>&1 && cd pet-theory/lab08) & spinner
echo -e "\r${GREEN}✓ Repository cloned and directory changed${RESET}"
echo "${CYAN}Video tutorials: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Build and deploy frontend service
section_header "FRONTEND DEPLOYMENT"
echo "${BLUE}Building and deploying frontend service...${RESET}"
(gcloud run deploy frontend --source . --platform managed --region $REGION --allow-unauthenticated > /dev/null 2>&1) & spinner
echo -e "\r${GREEN}✓ Frontend service deployed${RESET}"
echo "${CYAN}Learn more at: https://www.youtube.com/@drabhishek.5460${RESET}"
echo

# Final completion message
section_header "LAB COMPLETED"
echo "${GREEN}🎉 Cloud Run deployment completed successfully!${RESET}"
echo
echo "${MAGENTA}For more cloud engineering tutorials:${RESET}"
echo "${CYAN}Subscribe to Dr. Abhishek's YouTube channel:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo "${BLUE}Video tutorials: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Cleanup
SCRIPT_NAME="abhishek.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo "${RED}Removing temporary script file...${RESET}"
    rm -- "$SCRIPT_NAME"
fi
