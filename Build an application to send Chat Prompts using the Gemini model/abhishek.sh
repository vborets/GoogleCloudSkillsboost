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
BOLD=$'\033[1m'
RESET=$'\033[0m'
UNDERLINE=$'\033[4m'

# Background Colors
BG_BLUE=$'\033[44m'
BG_GREEN=$'\033[42m'

clear

# Enhanced Welcome Banner
echo "${BLUE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BLUE}${BOLD}║                                                        ║${RESET}"
echo "${BLUE}${BOLD}║   ${WHITE}${BG_BLUE}🚀WELCOME TO DR ABHISHEK CLOUD TUTORIALS ${RESET}${BLUE}${BOLD}               ║${RESET}"
echo "${BLUE}${BOLD}║                                                        ║${RESET}"
echo "${BLUE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

LAB_MODEL="gemini-2.0-flash-001"

# Get region input with validation
while true; do
    echo "${YELLOW}${BOLD}🌍 Enter Google Cloud Region (e.g., us-central1):${RESET}"
    read -r REGION
    if [ -n "$REGION" ]; then
        export REGION
        echo "${GREEN}✓ ${WHITE}Region set to: ${CYAN}${BOLD}$REGION${RESET}"
        break
    else
        echo "${RED}✗ Region cannot be empty. Please try again.${RESET}"
    fi
done
echo

# Get Project ID
echo "${YELLOW}${BOLD}🔍 Retrieving Project ID...${RESET}"
ID="$(gcloud projects list --format='value(PROJECT_ID)' | head -1)"
if [ -z "$ID" ]; then
    echo "${RED}${BOLD}Error: Could not retrieve Project ID. Please ensure:"
    echo "1. You're authenticated with gcloud (run 'gcloud auth login')"
    echo "2. You have at least one project created${RESET}"
    exit 1
fi
echo "${GREEN}✓ ${WHITE}Project ID: ${CYAN}${BOLD}$ID${RESET}"
echo
echo "${GREEN}✓ ${WHITE}Using Model: ${MAGENTA}${BOLD}$LAB_MODEL${RESET}"
echo

# Create non-streaming chat script
SCRIPT1_PATH="/home/student/SendChatwithoutStream.py"
echo "${MAGENTA}${BOLD}📝 Creating non-streaming chat script...${RESET}"

cat > "$SCRIPT1_PATH" <<EOF
from google import genai
from google.genai.types import HttpOptions, ModelContent, Part, UserContent

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='$ID',
    location='$REGION',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(
    model="$LAB_MODEL",
    history=[
        UserContent(parts=[Part(text="Hello")]),
        ModelContent(
            parts=[Part(text="Great to meet you. What would you like to know?")],
        ),
    ],
)
response = chat.send_message("What are all the colors in a rainbow?")
logging.info(f'Received response 1: {response.text}')
print("${BLUE}${BOLD}First response:${RESET}")
print(response.text)

response = chat.send_message("Why does it appear when it rains?")
logging.info(f'Received response 2: {response.text}')
print("\n${BLUE}${BOLD}Second response:${RESET}")
print(response.text)
EOF

echo "${GREEN}✓ Script created: ${CYAN}$SCRIPT1_PATH${RESET}"
echo
echo "${YELLOW}${BOLD}💬 Executing non-streaming chat...${RESET}"
echo "${BLUE}────────────────────────────────────────────────────${RESET}"
if sudo -u student /usr/bin/python3 "$SCRIPT1_PATH"; then
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${GREEN}✓ Non-streaming chat completed successfully${RESET}"
else
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${RED}✗ Non-streaming chat failed${RESET}"
fi
echo
sleep 2

# Create streaming chat script
SCRIPT2_PATH="/home/student/SendChatwithStream.py"
echo "${MAGENTA}${BOLD}📝 Creating streaming chat script...${RESET}"

cat > "$SCRIPT2_PATH" <<EOF
from google import genai
from google.genai.types import HttpOptions

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='$ID',
    location='$REGION',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(model="$LAB_MODEL")
response_text = ""

logging.info("Sending streaming prompt...")
print("${BLUE}${BOLD}Streaming response:${RESET}")
for chunk in chat.send_message_stream("What are all the colors in a rainbow?"):
    print(chunk.text, end="")
    response_text += chunk.text
print()
logging.info(f"Received full streaming response: {response_text}")
EOF

echo "${GREEN}✓ Script created: ${CYAN}$SCRIPT2_PATH${RESET}"
echo
echo "${YELLOW}${BOLD}💬 Executing streaming chat...${RESET}"
echo "${BLUE}────────────────────────────────────────────────────${RESET}"
if sudo -u student /usr/bin/python3 "$SCRIPT2_PATH"; then
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${GREEN}✓ Streaming chat completed successfully${RESET}"
else
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${RED}✗ Streaming chat failed${RESET}"
fi
echo
sleep 2

# Completion Banner
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║                                                        ║${RESET}"
echo "${GREEN}${BOLD}║   ${WHITE}${BG_GREEN}✅ LAB COMPLETED SUCCESSFULLY ✅${RESET}${GREEN}${BOLD}   ║${RESET}"
echo "${GREEN}${BOLD}║                                                        ║${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${WHITE}${BOLD}For more cloud AI tutorials and guides:${RESET}"
echo "${YELLOW}👉 Subscribe to Dr. Abhishek Cloud Tutorials:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
echo "${MAGENTA}Thank you do like share & subscribe!${RESET}"
echo
