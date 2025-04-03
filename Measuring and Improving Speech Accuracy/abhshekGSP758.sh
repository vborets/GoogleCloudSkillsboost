#!/bin/bash

# Define color variables
BLACK='\033[0;90m'
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color

# Text formatting
BOLD='\033[1m'
UNDERLINE='\033[4m'

clear

# Welcome message
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}       WELCOME TO DR ABHISHEK CHANNEL       ${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo

# Prompt user for input
read -p "$(echo -e ${WHITE}${BOLD}Enter your GCP Zone (e.g. us-central1-a): ${NC})" ZONE

echo -e "${YELLOW}${BOLD}Enabling required GCP services...${NC}"
gcloud services enable notebooks.googleapis.com
gcloud services enable aiplatform.googleapis.com

sleep 15

# Notebook creation
echo -e "${CYAN}${BOLD}Creating new AI Notebook instance...${NC}"
echo -e "${YELLOW}This may take a few minutes. Please wait.${NC}"
echo

export NOTEBOOK_NAME="lab-workbench"
export MACHINE_TYPE="e2-standard-2"

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu

echo -e "${GREEN}${BOLD}Notebook instance created successfully!${NC}"

# Display access information
PROJECT_ID=$(gcloud config get-value project)
echo -e "${YELLOW}${BOLD}You can access your notebook at:${NC}"
echo -e "${BLUE}https://console.cloud.google.com/vertex-ai/workbench/user-managed?project=${PROJECT_ID}${NC}"

# Completion message
echo
echo -e "${GREEN}${BOLD}=========================================${NC}"
echo -e "${GREEN}${BOLD}       DO HIT LIKE & SUBSCRIBE BUTTON     ${NC}"
echo -e "${GREEN}${BOLD}=========================================${NC}"
echo
echo -e "${WHITE}For more tutorials, visit Dr. Abhishek's YouTube channel:${NC}"
echo -e "${CYAN}https://www.youtube.com/@drabhishek.5460/playlists${NC}"
echo
echo -e "${WHITE}Please follow the remaining instructions from video.${NC}"
