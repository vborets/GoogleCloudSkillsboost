#!/bin/bash


HEADER_COLOR=$'\033[38;5;54m'       # Deep purple
TITLE_COLOR=$'\033[38;5;93m'         # Bright purple
PROMPT_COLOR=$'\033[38;5;178m'       # Gold
ACTION_COLOR=$'\033[38;5;44m'        # Teal
SUCCESS_COLOR=$'\033[38;5;46m'       # Bright green
WARNING_COLOR=$'\033[38;5;196m'      # Bright red
LINK_COLOR=$'\033[38;5;27m'          # Blue
TEXT_COLOR=$'\033[38;5;255m'         # Bright white

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear


echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${TITLE_COLOR}${BOLD_TEXT}       🎓 DR. ABHISHEK'S CLOUD TUTORIALS      ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}This lab demonstrates Google Cloud Text-to-Speech API setup${RESET_FORMAT}"
echo "${TEXT_COLOR}and service account configuration.${RESET_FORMAT}"
echo

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
print_message "$ACTION_COLOR" "🆔" "Using Project ID: $PROJECT_ID"
echo

# Enable Text-to-Speech API
print_message "$ACTION_COLOR" "⚙️" "Enabling Text-to-Speech API..."
gcloud services enable texttospeech.googleapis.com --quiet
print_message "$SUCCESS_COLOR" "✓" "Text-to-Speech API enabled successfully"
echo

# Create service account
SERVICE_ACCOUNT_NAME="tts-service-account"
print_message "$ACTION_COLOR" "👤" "Creating service account '$SERVICE_ACCOUNT_NAME'..."
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --description="Service account for Text-to-Speech operations" \
    --display-name="Text-to-Speech Service Account" \
    --quiet
print_message "$SUCCESS_COLOR" "✓" "Service account created successfully"
echo

# Create service account key
KEY_FILE="tts-service-key.json"
print_message "$ACTION_COLOR" "🔑" "Generating service account key..."
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com \
    --quiet
print_message "$SUCCESS_COLOR" "✓" "Service account key saved to: $KEY_FILE"
echo

# Set credentials environment variable
print_message "$ACTION_COLOR" "🔧" "Configuring application credentials..."
export GOOGLE_APPLICATION_CREDENTIALS=$KEY_FILE
print_message "$SUCCESS_COLOR" "✓" "Credentials configured: $GOOGLE_APPLICATION_CREDENTIALS"
echo

# Completion message
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${SUCCESS_COLOR}${BOLD_TEXT}          🎉 LAB COMPLETED SUCCESSFULLY! 🎉         ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}${BOLD_TEXT}You've successfully completed these operations:${RESET_FORMAT}"
echo "${TEXT_COLOR}• Enabled Text-to-Speech API"
echo "• Created a dedicated service account"
echo "• Generated secure credentials"
echo "• Configured application environment${RESET_FORMAT}"
echo
echo -e "${PROMPT_COLOR}${BOLD_TEXT}💡 Continue learning at: ${LINK_COLOR}https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo "${PROMPT_COLOR}${BOLD_TEXT}   Don't forget to like and subscribe!${RESET_FORMAT}"
echo
