#!/bin/bash

# Define color variables
BLUE='\033[0;94m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color

# Text formatting
BOLD='\033[1m'
UNDERLINE='\033[4m'

clear

# Welcome header
echo -e "${BLUE}${BOLD}╔════════════════════════════════════════╗"
echo -e "║           WELCOME TO DR ABHISHEK CHANNEL           ║"
echo -e "╚════════════════════════════════════════╝${NC}"
echo

# User input
read -p "$(echo -e ${WHITE}${BOLD}Enter your GCP Zone (e.g. us-central1-a): ${NC})" ZONE
echo

# Service activation
echo -e "${YELLOW}${BOLD}⚙️  Enabling required services...${NC}"
gcloud services enable notebooks.googleapis.com
gcloud services enable aiplatform.googleapis.com
sleep 15

# Notebook creation
echo -e "${CYAN}${BOLD}🖥️  Creating new AI Notebook instance...${NC}"
echo -e "${YELLOW}⏳ This may take a few minutes. Please wait.${NC}"
echo

export NOTEBOOK_NAME="lab-workbench"
export MACHINE_TYPE="e2-standard-2"

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu

# Success message
echo -e "${GREEN}${BOLD}✅ Notebook instance created successfully!${NC}"

# Access information
PROJECT_ID=$(gcloud config get-value project)
echo -e "${YELLOW}${BOLD}🔗 You can access your notebook at:${NC}"
echo -e "${BLUE}${UNDERLINE}https://console.cloud.google.com/vertex-ai/workbench/user-managed?project=${PROJECT_ID}${NC}"

# Footer
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗"
echo -e "║         LAB COMPLETED SUCCESSFULLY        ║"
echo -e "╚════════════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}For more cloud tutorials, visit:${NC}"
echo -e "${CYAN}${BOLD}Dr. Abhishek's YouTube Channel${NC}"
echo -e "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460${NC}"
echo
echo -e "${WHITE}Continue with  lab instructions.${NC}"
