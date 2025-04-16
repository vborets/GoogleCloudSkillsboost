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

# Header Section
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}         GEMINI STREAMLIT CLOUD RUN TUTORIAL            ${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}          Expert Tutorial by Dr. Abhishek              ${RESET}"
echo "${YELLOW}For more GenAI tutorials, visit: https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${BLUE}${BOLD}⚡ Initializing Gemini Streamlit Setup...${RESET}"
echo

# Authentication Check
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ AUTHENTICATION CHECK ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Checking authenticated accounts...${RESET}"
gcloud auth list
echo "${GREEN}✅ Authentication verified!${RESET}"
echo

# Service Enablement
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ SERVICE ENABLEMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com
echo "${GREEN}✅ Cloud Run API enabled!${RESET}"
echo

# Application Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ APPLICATION SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Cloning Generative AI repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/generative-ai.git
cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun
echo "${GREEN}✅ Repository cloned successfully!${RESET}"
echo

# File Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FILE CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Downloading configuration files...${RESET}"
rm -rf Dockerfile chef.py

# Updated file locations
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/Dockerfile.txt -O Dockerfile
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/chef.py
curl -LO  https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%3A%20Challenge%20Lab/bonustask.sh

echo "${YELLOW}Setting execute permission for bonus task...${RESET}"
chmod +x bonustask.sh

echo "${YELLOW}Uploading chef.py to Cloud Storage...${RESET}"
gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/
export PROJECT="$DEVSHELL_PROJECT_ID"
echo "${GREEN}✅ Files configured and uploaded!${RESET}"
echo

# Environment Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENVIRONMENT SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Installing required packages...${RESET}"
pip install google-cloud-aiplatform
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m pip install -r requirements.txt
echo "${GREEN}✅ Environment setup complete!${RESET}"
echo

# Application Execution
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ APPLICATION EXECUTION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Running Streamlit application...${RESET}"
streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080

# Bonus Task Execution
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ BONUS TASK ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Running bonus task...${RESET}"
./bonustask.sh
echo "${GREEN}✅ Bonus task completed!${RESET}"
echo

# Completion Message
echo "${BG_GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}         NOW ITS TIME FOR LAB STEPS FOLLOW VIDEO CAREFULLY              ${RESET}"
echo "${BG_GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}🙏 Thank you for following Dr. Abhishek's tutorial!${RESET}"
echo "${YELLOW}${BOLD}📺 Subscribe for more GenAI content:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${MAGENTA}${BOLD}🚀 Happy building with Gemini and Streamlit!${RESET}"
