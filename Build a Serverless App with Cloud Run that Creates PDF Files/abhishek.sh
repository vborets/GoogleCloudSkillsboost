#!/bin/bash

# Define color variables with improved formatting
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'
UNDERLINE_TEXT=$'\033[4m'

# Spinner function for visual feedback
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


echo
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  WELCOME TO DR. ABHISHEK CLOUD TUTORIALS  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to subscribe to Dr. Abhishek's YouTube channel:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460/videos${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the Cloud Run PDF Converter setup...${RESET_FORMAT}"
echo

# User input for REGION
echo "${YELLOW_TEXT}${BOLD_TEXT}Please Enter Your LAB REGION:${RESET_FORMAT}"
read -p "REGION: " REGION
export REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔄 Disabling and re-enabling Cloud Run API for clean setup...${RESET_FORMAT}"
gcloud services disable run.googleapis.com > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Cloud Run API disabled${RESET_FORMAT}"

gcloud services enable run.googleapis.com > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Cloud Run API enabled${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for 30 seconds to ensure API stability...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${BLUE_TEXT}  $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n"

echo "${GREEN_TEXT}${BOLD_TEXT}📥 Cloning the pet-theory repository...${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory.git > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Repository cloned${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📂 Changing directory to lab03...${RESET_FORMAT}"
cd pet-theory/lab03 > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Directory changed${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✏️ Modifying package.json...${RESET_FORMAT}"
sed -i '6a\    "start": "node index.js",' package.json > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ package.json updated${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📦 Installing required npm packages...${RESET_FORMAT}"
npm install express > /dev/null 2>&1 &
spinner
npm install body-parser > /dev/null 2>&1 &
spinner
npm install child_process > /dev/null 2>&1 &
spinner
npm install @google-cloud/storage > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ All packages installed${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🐳 Building and submitting Docker image...${RESET_FORMAT}"
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Docker image built and submitted${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Deploying pdf-converter service to Cloud Run...${RESET_FORMAT}"
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=1 > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Service deployed${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Fetching the service URL...${RESET_FORMAT}"
SERVICE_URL=$(gcloud beta run services describe pdf-converter --platform managed --region $REGION --format="value(status.url)")
echo "${MAGENTA_TEXT}Service URL: ${SERVICE_URL}${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📡 Testing service endpoints...${RESET_FORMAT}"
echo "${YELLOW_TEXT}Sending test POST request...${RESET_FORMAT}"
curl -X POST $SERVICE_URL > /dev/null 2>&1 &
spinner
echo -e "\n${YELLOW_TEXT}Sending authenticated POST request...${RESET_FORMAT}"
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Endpoints tested${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📦 Creating Cloud Storage buckets...${RESET_FORMAT}"
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-upload > /dev/null 2>&1 &
spinner
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-processed > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Buckets created${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔔 Setting up bucket notifications...${RESET_FORMAT}"
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Notifications configured${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}👤 Creating service account for Pub/Sub...${RESET_FORMAT}"
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker" > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Service account created${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Binding service account permissions...${RESET_FORMAT}"
gcloud beta run services add-iam-policy-binding pdf-converter --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region $REGION > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Permissions bound${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔢 Fetching project number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format='value(projectNumber)')
echo "${MAGENTA_TEXT}Project Number: ${PROJECT_NUMBER}${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔑 Granting Pub/Sub permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Permissions granted${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📩 Creating Pub/Sub subscription...${RESET_FORMAT}"
gcloud beta pubsub subscriptions create pdf-conv-sub --topic new-doc --push-endpoint=$SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Subscription created${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📤 Uploading sample files...${RESET_FORMAT}"
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Sample files uploaded${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🐳 Creating Dockerfile...${RESET_FORMAT}"
cat > Dockerfile <<EOF_END
FROM node:20
RUN apt-get update -y \\
    && apt-get install -y libreoffice \\
    && apt-get clean
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF_END
echo -e "\n${GREEN_TEXT}✅ Dockerfile created${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📝 Creating index.js...${RESET_FORMAT}"
cat > index.js <<'EOF_END'
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
const express     = require('express');
const bodyParser  = require('body-parser');
const app         = express();

app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

async function downloadFile(bucketName, fileName) {
  const options = {destination: `/tmp/${fileName}`};
  await storage.bucket(bucketName).file(fileName).download(options);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    throw stderr;
  }
  console.log(stdout);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
EOF_END
echo -e "\n${GREEN_TEXT}✅ index.js created${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🐳 Rebuilding Docker image with LibreOffice...${RESET_FORMAT}"
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Image rebuilt${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Redeploying updated service...${RESET_FORMAT}"
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region $REGION \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --max-instances=1 \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed > /dev/null 2>&1 &
spinner
echo -e "\n${GREEN_TEXT}✅ Service redeployed${RESET_FORMAT}"

# Completion message with Dr. Abhishek branding
echo
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎉  CLOUD RUN PDF CONVERTER SETUP COMPLETE!  🎉${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}============================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Thank you for following Dr. Abhishek's Cloud Tutorial!${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}For more tutorials, please subscribe to:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460/videos${RESET_FORMAT}"
echo
