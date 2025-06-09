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

# Display banner
clear
echo "${CYAN}${BOLD}"
echo "   ____  ____    __  ___   ___  ___  ___  __  __  ____  _  _  ____ "
echo "  (  _ \( ___)  /__\( _ ) / __)/ __)/ __)(  )(  )( ___)( \( )(_  _)"
echo "   )   / )__)  /(__)) _ \( (__ \__ \\__ \ )(__)(  )__)  )  (   )(  "
echo "  (_)\_)(____)(__)(____/ \___)(___/(___/(______)(____)(_)\_) (__) "
echo "${RESET}"
echo "${BG_MAGENTA}${BOLD}  DR. ABHISHEK'S CLOUD PUB/SUB form id I ${RESET}"
echo
echo "${WHITE}📺 YouTube: ${BLUE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo "${WHITE}⭐ Please Subscribe for More Cloud Tutorials! ⭐${RESET}"
echo

#----------------------------------------------------start--------------------------------------------------#

echo "${GREEN}${BOLD}Step 1: Creating Pub/Sub Subscription${RESET}"
gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic || {
    echo "${RED}${BOLD}Error: Failed to create subscription${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}Step 2: Publishing Test Message${RESET}"
gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello from Dr. Abhishek's Lab" || {
    echo "${RED}${BOLD}Error: Failed to publish message${RESET}"
    exit 1
}

echo "${YELLOW}${BOLD}Waiting 10 seconds for message propagation...${RESET}"
for i in {10..1}; do
    printf "\r${CYAN}${BOLD}Time remaining: %2d seconds...${RESET}" $i
    sleep 1
done
printf "\n"

echo "${GREEN}${BOLD}Step 3: Retrieving Messages${RESET}"
gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5 || {
    echo "${RED}${BOLD}Error: Failed to pull messages${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}Step 4: Creating Snapshot${RESET}"
gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription || {
    echo "${RED}${BOLD}Error: Failed to create snapshot${RESET}"
    exit 1
}

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab!${RESET}"
echo
echo "${MAGENTA}${BOLD}Don't forget to subscribe to Dr. Abhishek's YouTube channel:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@drabhishek.5460${RESET}"
echo

#-----------------------------------------------------end----------------------------------------------------------#
