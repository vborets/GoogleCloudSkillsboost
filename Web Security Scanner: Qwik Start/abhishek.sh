#!/bin/bash
# Color Definitions
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

# Clear screen and display header
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}      Welcome to Dr Abhishek Cloud Tutorials      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

# Get region input with improved colors
echo -n "${GREEN_TEXT}${BOLD_TEXT}✏️  Please enter  region (e.g., us-central1): ${RESET_FORMAT}"
read REGION
export REGION
echo

# Process steps with enhanced visual feedback
echo "${BLUE_TEXT}${BOLD_TEXT}📦 Step 1: Copying files from Cloud Storage...${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp067/python-docs-samples .
echo "${GREEN_TEXT}✓ Files copied successfully${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📂 Step 2: Navigating to application directory...${RESET_FORMAT}"
cd python-docs-samples/appengine/standard_python3/hello_world
echo "${GREEN_TEXT}✓ Directory changed${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️  Step 3: Updating app.yaml for Python 3.9...${RESET_FORMAT}"
sed -i "s/python37/python39/g" app.yaml
echo "${GREEN_TEXT}✓ Configuration updated${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Step 4: Creating App Engine application in ${REGION}...${RESET_FORMAT}"
gcloud app create --region=$REGION
echo "${GREEN_TEXT}✓ App Engine instance created${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️  Step 5: Deploying application...${RESET_FORMAT}"
yes | gcloud app deploy
echo "${GREEN_TEXT}✓ Deployment complete${RESET_FORMAT}"
echo

# Final message with improved styling
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}          TUTORIAL COMPLETE!          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}💡 Learn more at Dr Abhishek Cloud Tutorials:${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460/${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}👍 Don't forget to like and subscribe for more cloud tutorials!${RESET_FORMAT}"
echo
