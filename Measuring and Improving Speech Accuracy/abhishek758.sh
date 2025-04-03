#!/bin/bash

# Define color variables
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Text formatting
BOLD='\033[1m'
UNDERLINE='\033[4m'

clear

# Welcome header
echo -e "${BLUE}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║                    WELCOME TO DR ABHISHEK CHANNEL     ║${NC}"
echo -e "${BLUE}${BOLD}╚════════════════════════════════════════╝${NC}"
echo

# User input
echo -e "${WHITE}${BOLD}┌────────────────────────────────────────┐${NC}"
read -p "$(echo -e ${WHITE}${BOLD}│ Enter your GCP Zone (e.g. us-central1-a): ${NC})" ZONE
echo -e "${WHITE}${BOLD}└────────────────────────────────────────┘${NC}"

# Service activation
echo -e "${YELLOW}${BOLD}⌛ Enabling required GCP services...${NC}"
gcloud services enable notebooks.googleapis.com
gcloud services enable aiplatform.googleapis.com
sleep 15

# Notebook creation
echo -e "${CYAN}${BOLD}🛠️  Creating new AI Notebook instance...${NC}"
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
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║        DO LIKE SHARE AND SUBCRIBE   ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}For more cloud tutorials, visit:${NC}"
echo -e "${CYAN}${BOLD}• Dr. Abhishek's YouTube Channel${NC}"
echo -e "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460${NC}"
echo
echo -e "${WHITE}Continue with your lab instructions.${NC}"
