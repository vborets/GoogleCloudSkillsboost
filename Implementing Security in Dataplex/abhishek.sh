#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        Welcome to Dr. Abhishek's Cloud Tutorials         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     STARTING LAB     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

# Spinner function
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

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Detecting GCP region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Could not automatically detect GCP region.${RESET_FORMAT}"
    read -p "${CYAN_TEXT}${BOLD_TEXT}Please enter the GCP region: ${RESET_FORMAT}" REGION
    export REGION
fi

echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Region set to: $REGION${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️  Enabling the Dataplex API. This is a necessary step for using Dataplex services.${RESET_FORMAT}"
(gcloud services enable dataplex.googleapis.com) & spinner

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📚 Enabling the Data Catalog API. This service helps in discovering and managing data assets.${RESET_FORMAT}"
(gcloud services enable datacatalog.googleapis.com) & spinner

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🏞️  Creating new Dataplex lake named 'customer-info-lake'...${RESET_FORMAT}"
(gcloud dataplex lakes create customer-info-lake \
    --location=$REGION \
    --display-name="Customer Info Lake") & spinner

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🧱 Creating RAW zone named 'customer-raw-zone'...${RESET_FORMAT}"
(gcloud alpha dataplex zones create customer-raw-zone \
    --location=$REGION --lake=customer-info-lake \
    --resource-location-type=SINGLE_REGION --type=RAW \
    --display-name="Customer Raw Zone") & spinner

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🧺 Creating Dataplex asset named 'customer-online-sessions'...${RESET_FORMAT}"
(gcloud dataplex assets create customer-online-sessions --location=$REGION \
    --lake=customer-info-lake --zone=customer-raw-zone \
    --resource-type=STORAGE_BUCKET \
    --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-bucket \
    --display-name="Customer Online Sessions") & spinner

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${RESET_FORMAT}""${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataplex/secure?resourceName=projects%2F$DEVSHELL_PROJECT_ID%2Flocations%2F$REGION%2Flakes%2Fcustomer-info-lake&project=$DEVSHELL_PROJECT_ID""${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE TO MY CHANNEL! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo
