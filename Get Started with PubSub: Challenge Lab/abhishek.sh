#!/bin/bash

# Define color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

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


echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}       Welcome to Dr. Abhishek Cloud Tutorials!           ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${GREEN}${BOLD}Please like, share and subscribe to the channel for more:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Function to run form 1 code
run_form_1() {
    echo "${YELLOW}${BOLD}Starting Pub/Sub Scheduler Lab...${RESET}"
    
    gcloud services enable cloudscheduler.googleapis.com
    gcloud pubsub topics create cloud-pubsub-topic
    gcloud pubsub subscriptions create 'cloud-pubsub-subscription' --topic=cloud-pubsub-topic
    gcloud scheduler jobs create pubsub cron-scheduler-job \
        --schedule="* * * * *" --topic=cron-job-pubsub-topic \
        --message-body="Hello World!" --location=$REGION
    gcloud pubsub subscriptions pull cron-job-pubsub-subscription --limit 5
    
    echo "${GREEN}${BOLD}Form 1 Lab Completed Successfully!${RESET}"
}

# Function to run form 2 code
run_form_2() {
    echo "${YELLOW}${BOLD}Starting Pub/Sub Schema Lab...${RESET}"
    
    gcloud beta pubsub schemas create city-temp-schema \
        --type=avro \
        --definition='{
            "type": "record",
            "name": "Avro",
            "fields": [
                {"name": "city", "type": "string"},
                {"name": "temperature", "type": "double"},
                {"name": "pressure", "type": "int"},
                {"name": "time_position", "type": "string"}
            ]
        }'

    gcloud pubsub topics create temp-topic \
        --message-encoding=JSON \
        --message-storage-policy-allowed-regions=$REGION \
        --schema=projects/$DEVSHELL_PROJECT_ID/schemas/temperature-schema

    mkdir quicklab && cd $_

    cat >index.js <<'EOF_END'
/**
* Triggered from a message on a Cloud Pub/Sub topic.
*
* @param {!Object} event Event payload.
* @param {!Object} context Metadata for the event.
*/
exports.helloPubSub = (event, context) => {
const message = event.data
    ? Buffer.from(event.data, 'base64').toString()
    : 'Hello, World';
console.log(message);
};
EOF_END

    cat >package.json <<'EOF_END'
{
"name": "sample-pubsub",
"version": "0.0.1",
"dependencies": {
    "@google-cloud/pubsub": "^0.18.0"
}
}
EOF_END

    deploy_function() {
        gcloud functions deploy gcf-pubsub \
            --trigger-topic=gcf-topic \
            --runtime=nodejs20 \
            --no-gen2 \
            --entry-point=helloPubSub \
            --source=. \
            --region=$REGION
    }

    deploy_success=false
    attempts=0
    max_attempts=5

    while [ "$deploy_success" = false ] && [ $attempts -lt $max_attempts ]; do
        if deploy_function; then
            echo "${GREEN}Function deployed successfully!${RESET}"
            deploy_success=true
        else
            attempts=$((attempts+1))
            echo "${YELLOW}Attempt $attempts: Waiting for Cloud Function to be deployed...${RESET}"
            sleep 20
        fi
    done

    if [ "$deploy_success" = false ]; then
        echo "${RED}Failed to deploy function after $max_attempts attempts.${RESET}"
    fi
    
    echo "${GREEN}${BOLD}Form 2 Lab Completed Successfully!${RESET}"
}

# Function to run form 3 code
run_form_3() {
    echo "${YELLOW}${BOLD}Starting Pub/Sub Snapshot Lab...${RESET}"
    
    gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic
    gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"
    sleep 10
    gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5
    gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription
    
    echo "${GREEN}${BOLD}Form 3 Lab Completed Successfully!${RESET}"
}

# Main script execution
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}           Google Cloud Pub/Sub Lab ID Selection             ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

echo "${YELLOW}${BOLD}"
read -p "Enter the REGION: " REGION
echo "${RESET}"

echo "${BLUE}${BOLD}"
read -p "Enter the Form number (1, 2, or 3): " form_number
echo "${RESET}"

# Execute the selected lab
case $form_number in
1) run_form_1 ;;
2) run_form_2 ;;
3) run_form_3 ;;
*) echo "${RED}Invalid form number. Please enter 1, 2, or 3.${RESET}" ;;
esac


echo
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}           Lab  Completed Successfully!          ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${GREEN}${BOLD}Thanks for using this lab! Don't forget to:${RESET}"
echo "${YELLOW}${BOLD}👍 Like   🔄 Share   🔔 Subscribe${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
