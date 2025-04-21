#!/bin/bash


DARK_BLUE=$'\033[38;5;27m'
TEAL=$'\033[38;5;50m'
PURPLE=$'\033[38;5;129m'
ORANGE=$'\033[38;5;208m'
LIME=$'\033[38;5;118m'
PINK=$'\033[38;5;200m'
RED=$'\033[38;5;196m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'


DIVIDER="${DARK_BLUE}${BOLD}┃${RESET}"
TOP_CORNER="${DARK_BLUE}${BOLD}╭${RESET}"
BOTTOM_CORNER="${DARK_BLUE}${BOLD}╰${RESET}"
LINE="${DARK_BLUE}${BOLD}─${RESET}"

clear

# Modern Header
echo
echo "${TOP_CORNER}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${RESET}"
echo "${DARK_BLUE}${BOLD}             WELCOME TO DR ABHISHEK               ${RESET}"
echo "${DARK_BLUE}${BOLD}                CLOUD TUTORIAL            ${RESET}"
echo "${BOTTOM_CORNER}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${LINE}${RESET}"
echo

# Function to display progress spinner
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

# Function to deploy services with retry logic
deploy_service() {
    local service_name=$1
    local image_name=$2
    local allow_unauthenticated=$3
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        echo -n "${TEAL}${BOLD}Deploying $service_name...${RESET}"
        (gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$image_name && \
         gcloud run deploy $service_name \
            --image gcr.io/$GOOGLE_CLOUD_PROJECT/$image_name \
            --platform managed \
            --region $REGION \
            $allow_unauthenticated \
            --max-instances=1) > /dev/null 2>&1 &
        spinner
        
        if [ $? -eq 0 ]; then
            echo "${LIME}${BOLD}✔ $service_name deployed successfully${RESET}"
            return 0
        else
            retry_count=$((retry_count+1))
            echo "${RED}${BOLD}✘ Deployment failed, retrying ($retry_count/$max_retries)...${RESET}"
            sleep 5
        fi
    done
    
    echo "${RED}${BOLD}✘ Failed to deploy $service_name after $max_retries attempts${RESET}"
    return 1
}

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

# Step 6: Email Service Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 6: EMAIL SERVICE SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Configuring email-service...${RESET}"
cd ~/pet-theory/lab05/email-service
npm install express body-parser

cat > package.json <<EOF
{
  "name": "email-service",
  "version": "1.0.0",
  "description": "Email service for Pet Theory",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "body-parser": "^1.20.2",
    "express": "^4.18.2"
  }
}
EOF

cat > index.js <<EOF
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Email service listening on port', port);
});
app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(\`Email Service: Report \${labReport.id} processing...\`);
    sendEmail();
    console.log(\`Email Service: Report \${labReport.id} completed\`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(\`Email Service: Report \${labReport.id} failed: \${ex}\`);
    res.status(500).send();
  }
});
function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}
function sendEmail() {
  console.log('Sending email notification');
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

echo "${LIME}${BOLD}✔ email-service configured successfully${RESET}"
echo

# Step 7: Service Account Creation
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 7: SERVICE ACCOUNT SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Creating service account...${RESET}"
gcloud iam service-accounts create pubsub-cloud-run-invoker \
  --display-name "PubSub Cloud Run Invoker"
echo "${LIME}${BOLD}✔ Service account created${RESET}"
echo

# Step 8: IAM Policy Binding
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 8: IAM PERMISSIONS ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Configuring IAM permissions...${RESET}"
gcloud run services add-iam-policy-binding email-service \
  --member="serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region $REGION \
  --platform managed

PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

echo "${LIME}${BOLD}✔ IAM permissions configured${RESET}"
echo

# Step 9: Email Service Deployment
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 9: EMAIL SERVICE DEPLOYMENT ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
deploy_service "email-service" "email-service" "--no-allow-unauthenticated"
EMAIL_SERVICE_URL=$(gcloud run services describe email-service --platform managed --region=$REGION --format="value(status.address.url)")
echo "${LIME}${BOLD}✔ Email service URL: $EMAIL_SERVICE_URL${RESET}"
echo

# Step 10: Pub/Sub Subscription
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 10: PUB/SUB SUBSCRIPTION ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Creating Pub/Sub subscription...${RESET}"
gcloud pubsub subscriptions create email-service-sub \
  --topic new-lab-report \
  --push-endpoint=$EMAIL_SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
echo "${LIME}${BOLD}✔ Subscription created${RESET}"
echo

# Step 11: SMS Service Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 11: SMS SERVICE SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Configuring SMS service...${RESET}"
cd ~/pet-theory/lab05/sms-service
npm install express body-parser

cat > package.json <<EOF
{
  "name": "sms-service",
  "version": "1.0.0",
  "description": "SMS service for Pet Theory",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "body-parser": "^1.20.2",
    "express": "^4.18.2"
  }
}
EOF

cat > index.js <<EOF
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('SMS service listening on port', port);
});
app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(\`SMS Service: Report \${labReport.id} processing...\`);
    sendSms();
    console.log(\`SMS Service: Report \${labReport.id} completed\`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(\`SMS Service: Report \${labReport.id} failed: \${ex}\`);
    res.status(500).send();
  }
});
function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}
function sendSms() {
  console.log('Sending SMS notification');
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

echo "${LIME}${BOLD}✔ SMS service configured successfully${RESET}"
echo

# Step 12: SMS Service Deployment
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 12: SMS SERVICE DEPLOYMENT ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
deploy_service "sms-service" "sms-service" "--no-allow-unauthenticated"
echo "${LIME}${BOLD}✔ SMS service deployed successfully${RESET}"
echo

# Step 13: Lab Report Service Deployment
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 13: LAB REPORT SERVICE DEPLOYMENT ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
deploy_service "lab-report-service" "lab-report-service" "--allow-unauthenticated"
LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region=$REGION --format="value(status.address.url)")
echo "${LIME}${BOLD}✔ Lab report service URL: $LAB_REPORT_SERVICE_URL${RESET}"
echo

# Step 14: Post Reports Script
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 14: TESTING SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo "${TEAL}${BOLD}Creating test script...${RESET}"
cat > post-reports.sh <<EOF
#!/bin/bash
echo "Testing lab report service..."
curl -X POST -H "Content-Type: application/json" -d '{"id": 12}' $LAB_REPORT_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d '{"id": 34}' $LAB_REPORT_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d '{"id": 56}' $LAB_REPORT_SERVICE_URL &
EOF

chmod +x post-reports.sh
echo "${LIME}${BOLD}✔ Test script created${RESET}"
echo

# Step 15: Execute Tests
echo "${TEAL}${BOLD}Executing test requests...${RESET}"
./post-reports.sh
echo "${LIME}${BOLD}✔ Test requests sent${RESET}"
echo

# Cleanup
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo "${TEAL}${BOLD}Cleaning up temporary files...${RESET}"
    rm -- "$SCRIPT_NAME"
    echo "${LIME}${BOLD}✔ Cleanup complete${RESET}"
    echo
fi

# Final Completion Message
echo
echo "${PINK}${BOLD}╭──────────────────────────────────────────────────────────────╮${RESET}"
echo "${PINK}${BOLD}│    🎉 Cloud Services Deployment Completed Successfully!    │${RESET}"
echo "${PINK}${BOLD}│    🔍 Explore your services in Google Cloud Console         │${RESET}"
echo "${PINK}${BOLD}╰──────────────────────────────────────────────────────────────╯${RESET}"
echo
echo "${DARK_BLUE}${BOLD}For more cloud engineering tutorials, visit:${RESET}"
echo "${TEAL}${BOLD}   https://www.youtube.com/@drabhishek.5460/${RESET}"
echo
echo "${DIM}${DARK_BLUE}Like and subscribe for more cloud architecture content! ${RESET}"
echo
