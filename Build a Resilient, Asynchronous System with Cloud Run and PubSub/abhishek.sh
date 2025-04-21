#!/bin/bash

DARK_BLUE=$'\033[38;5;27m'
TEAL=$'\033[38;5;50m'
PURPLE=$'\033[38;5;129m'
ORANGE=$'\033[38;5;208m'
LIME=$'\033[38;5;118m'
PINK=$'\033[38;5;200m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'


DIVIDER="${DARK_BLUE}${BOLD}┃${RESET}"
TOP_CORNER="${DARK_BLUE}${BOLD}╭${RESET}"
BOTTOM_CORNER="${DARK_BLUE}${BOLD}╰${RESET}"
LINE="${DARK_BLUE}${BOLD}─${RESET}"

clear


echo
echo "${TOP_CORNER}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${RESET}"
echo "${DARK_BLUE}${BOLD}              WELCOME TO DR ABHISHEK CLOUD              ${RESET}"
echo "${DARK_BLUE}${BOLD}               TUTORIALS            ${RESET}"
echo "${BOTTOM_CORNER}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${RESET}"
echo

# Step 1: Zone Configuration
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 1: CONFIGURE COMPUTE ZONE ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
while true; do
    read -p "${TEAL}${BOLD}🌍 Enter Compute Zone (e.g., us-central1-a): ${RESET}" ZONE
    if [[ -n "$ZONE" ]]; then
        export ZONE
        break
    else
        echo "${RED}Zone cannot be empty. Please try again.${RESET}"
    fi
done

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

echo "${TEAL}${BOLD}Configuring compute zone and region...${RESET}"
gcloud config set compute/zone $ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
echo "${LIME}${BOLD}✔ Compute zone ($ZONE) and region ($REGION) configured${RESET}"
echo

# Step 2: Pub/Sub Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 2: PUB/SUB CONFIGURATION ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Creating Pub/Sub topic...${RESET}"
gcloud pubsub topics create new-lab-report
echo "${LIME}${BOLD}✔ Pub/Sub topic 'new-lab-report' created${RESET}"
echo

# Step 3: Cloud Run Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 3: CLOUD RUN SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com
echo "${LIME}${BOLD}✔ Cloud Run API enabled${RESET}"
echo

# Step 4: Repository Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 4: REPOSITORY SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Cloning Pet Theory repository...${RESET}"
git clone https://github.com/rosera/pet-theory.git
echo "${LIME}${BOLD}✔ Repository cloned successfully${RESET}"
echo

# Step 5: Lab Service Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 5: LAB SERVICE SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Configuring lab-service...${RESET}"
cd pet-theory/lab05/lab-service
npm install express body-parser @google-cloud/pubsub

# Create configuration files
cat > package.json <<EOF
{
  "name": "lab05",
  "version": "1.0.0",
  "description": "Lab service for Pet Theory",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/pubsub": "^4.0.0",
    "body-parser": "^1.20.2",
    "express": "^4.18.2"
  }
}
EOF

cat > index.js <<EOF
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Lab service listening on port', port);
});
app.post('/', async (req, res) => {
  try {
    const labReport = req.body;
    await publishPubSubMessage(labReport);
    res.status(204).send();
  }
  catch (ex) {
    console.log(ex);
    res.status(500).send(ex);
  }
});
async function publishPubSubMessage(labReport) {
  const buffer = Buffer.from(JSON.stringify(labReport));
  await pubsub.topic('new-lab-report').publish(buffer);
}
EOF

cat > Dockerfile <<EOF
FROM node:14
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --only=production
COPY . .
CMD ["npm", "start"]
EOF

echo "${LIME}${BOLD}✔ lab-service configured successfully${RESET}"
echo



# Final Completion Message
echo
echo "${PINK}${BOLD}╭──────────────────────────────────────────────────────────────╮${RESET}"
echo "${PINK}${BOLD}│    🎉 Cloud Services Deployment Completed Successfully!    │${RESET}"
echo "${PINK}${BOLD}│    🔍 Do Like the video          │${RESET}"
echo "${PINK}${BOLD}╰──────────────────────────────────────────────────────────────╯${RESET}"
echo
echo "${DARK_BLUE}${BOLD}For more cloud engineering tutorials, visit:${RESET}"
echo "${TEAL}${BOLD}   https://www.youtube.com/@drabhishek.5460/${RESET}"
echo
echo "${DIM}${DARK_BLUE}Like and subscribe for more cloud architecture content! ${RESET}"
echo
