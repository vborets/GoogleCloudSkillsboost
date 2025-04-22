#!/bin/bash

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT_RED=$(tput setaf 9)
BRIGHT_GREEN=$(tput setaf 10)
BRIGHT_YELLOW=$(tput setaf 11)
BRIGHT_BLUE=$(tput setaf 12)
BRIGHT_MAGENTA=$(tput setaf 13)
BRIGHT_CYAN=$(tput setaf 14)
BRIGHT_WHITE=$(tput setaf 15)

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
BLINK=$(tput blink)
REVERSE=$(tput smso)

#----------------------------------------------------start--------------------------------------------------#
clear
echo "${BRIGHT_MAGENTA}${BOLD}🚀 Welcome to Dr abhishek cloud tutorial${RESET}"
echo "${BRIGHT_CYAN}${BOLD}🔔 Don't forget to SUBSCRIBE to Dr. Abhishek Cloud!${RESET}"
echo "${BRIGHT_YELLOW}${BOLD}📺 YouTube: https://www.youtube.com/@DrAbhishekCloud${RESET}"
echo ""

# Create bucket
echo "${BRIGHT_BLUE}${BOLD}🛠️ Creating Cloud Storage Bucket...${RESET}"
gsutil mb -p $DEVSHELL_PROJECT_ID \
    -c standard \
    -l us \
    gs://$DEVSHELL_PROJECT_ID-vcm/ || {
    echo "${BRIGHT_RED}${BOLD}❌ Failed to create bucket!${RESET}"
    exit 1
}

export BUCKET=$DEVSHELL_PROJECT_ID-vcm
echo "${BRIGHT_GREEN}${BOLD}✔ Bucket created: gs://${BUCKET}${RESET}"
echo ""

# Copy files
echo "${BRIGHT_BLUE}${BOLD}📦 Copying image files...${RESET}"
gsutil -m cp -r gs://spls/gsp223/images/* gs://${BUCKET} || {
    echo "${BRIGHT_RED}${BOLD}❌ Failed to copy images!${RESET}"
    exit 1
}

echo "${BRIGHT_BLUE}${BOLD}📄 Downloading data.csv...${RESET}"
gsutil cp gs://spls/gsp223/data.csv . || {
    echo "${BRIGHT_RED}${BOLD}❌ Failed to download data.csv!${RESET}"
    exit 1
}

# Modify and upload CSV
echo "${BRIGHT_BLUE}${BOLD}✏️ Updating data.csv...${RESET}"
sed -i -e "s/placeholder/${BUCKET}/g" ./data.csv || {
    echo "${BRIGHT_RED}${BOLD}❌ Failed to update data.csv!${RESET}"
    exit 1
}

gsutil cp ./data.csv gs://${BUCKET} || {
    echo "${BRIGHT_RED}${BOLD}❌ Failed to upload data.csv!${RESET}"
    exit 1
}

echo "${BRIGHT_GREEN}${BOLD}✔ Files successfully processed!${RESET}"
echo ""

# Instructions
echo "${BRIGHT_CYAN}${BOLD}🔗 Click here to proceed:${RESET}"
echo "${BLINK}${BRIGHT_BLUE}${BOLD}👉 https://console.cloud.google.com/vertex-ai/datasets/create?project=$DEVSHELL_PROJECT_ID 👈${RESET}"
echo ""
echo "${BRIGHT_YELLOW}${BOLD}❗❗ NOW ${RESET}${BRIGHT_WHITE}${REVERSE} FOLLOW ${RESET} ${BRIGHT_GREEN}${BOLD}VIDEO INSTRUCTIONS CAREFULLY❗❗${RESET}"
echo ""
echo "${BRIGHT_MAGENTA}${BOLD}👍 Don't forget to LIKE, SHARE, and SUBSCRIBE to Dr. Abhishek Cloud!${RESET}"
echo "${BRIGHT_CYAN}${BOLD}📺 YouTube: https://www.youtube.com/@DrAbhishekCloud${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
