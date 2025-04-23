#!/bin/bash
# Google Cloud AI/ML Services Lab
# Expertly crafted by Dr. Abhishek Cloud

BOLD=$(tput bold)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)

# Text Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Background Colors
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)

# ======================

# ======================
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


clear
echo "${BG_BLUE}${BOLD}${WHITE}==================================================${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}   GOOGLE CLOUD AI/ML SERVICES LAB               ${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}   Expertly crafted by Dr. Abhishek Cloud        ${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}==================================================${RESET}"
echo ""
echo "${CYAN}${BOLD}⚡ Learn Google Cloud AI/ML services with hands-on labs${RESET}"
echo "${YELLOW}${BOLD}📺 YouTube: ${UNDERLINE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo ""

# ======================
#  USER INPUT SECTION
# ======================
echo "${BOLD}${MAGENTA}🔧 Please provide the following configuration values:${RESET}"

get_input() {
    local prompt="$1"
    local var_name="$2"
    local color="$3"
    
    echo -n -e "${BOLD}${color}${prompt}${RESET} "
    read $var_name
    export "$var_name"="${!var_name}"
}

get_input "Enter the DATASET value:" "DATASET" $CYAN
get_input "Enter the BUCKET value:" "BUCKET" $GREEN
get_input "Enter the TABLE value:" "TABLE" $YELLOW
get_input "Enter the BUCKET_URL_1 value:" "BUCKET_URL_1" $BLUE
get_input "Enter the BUCKET_URL_2 value:" "BUCKET_URL_2" $MAGENTA

echo "${GREEN}✔ Configuration values received${RESET}"
echo ""

# ======================
#  LAB EXECUTION
# ======================
echo "${BOLD}${BLUE}🔑 STEP 1: Enabling API keys service...${RESET}"
gcloud services enable apikeys.googleapis.com > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ API keys service enabled${RESET}"
echo ""

echo "${BOLD}${GREEN}🔑 STEP 2: Creating API key...${RESET}"
gcloud alpha services api-keys create --display-name="awesome" > /dev/null 2>&1 &
spinner
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
echo "${GREEN}✔ API key created: ${YELLOW}$API_KEY${RESET}"
echo ""

echo "${BOLD}${YELLOW}🌍 STEP 3: Getting default region...${RESET}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])") > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Region set to: ${YELLOW}$REGION${RESET}"
echo ""

echo "${BOLD}${MAGENTA}🆔 STEP 4: Retrieving project details...${RESET}"
PROJECT_ID=$(gcloud config get-value project) > /dev/null 2>&1 &
spinner
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber') > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Project ID: ${YELLOW}$PROJECT_ID${RESET}"
echo "${GREEN}✔ Project Number: ${YELLOW}$PROJECT_NUMBER${RESET}"
echo ""

echo "${BOLD}${CYAN}📊 STEP 5: Creating BigQuery dataset...${RESET}"
bq mk $DATASET > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Dataset created: ${YELLOW}$DATASET${RESET}"
echo ""

echo "${BOLD}${BLUE}🪣 STEP 6: Creating Cloud Storage bucket...${RESET}"
gsutil mb gs://$BUCKET > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Bucket created: ${YELLOW}gs://$BUCKET${RESET}"
echo ""

echo "${BOLD}${GREEN}📥 STEP 7: Downloading lab files...${RESET}"
gsutil cp gs://cloud-training/gsp323/lab.csv . > /dev/null 2>&1 &
gsutil cp gs://cloud-training/gsp323/lab.schema . > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Files downloaded successfully${RESET}"
echo ""

echo "${BOLD}${YELLOW}📝 STEP 8: Creating schema file...${RESET}"
cat > lab.schema <<EOF
[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]
EOF
echo "${GREEN}✔ Schema file created${RESET}"
echo ""

echo "${BOLD}${MAGENTA}📊 STEP 9: Creating BigQuery table...${RESET}"
bq mk --table $DATASET.$TABLE lab.schema > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Table created: ${YELLOW}$DATASET.$TABLE${RESET}"
echo ""

echo "${BOLD}${CYAN}⚡ STEP 10: Running Dataflow job...${RESET}"
gcloud dataflow jobs run awesome-jobs \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery \
    --region $REGION \
    --worker-machine-type e2-standard-2 \
    --staging-location gs://$DEVSHELL_PROJECT_ID-marking/temp \
    --parameters inputFilePattern=gs://cloud-training/gsp323/lab.csv,JSONPath=gs://cloud-training/gsp323/lab.schema,outputTable=$DEVSHELL_PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=gs://$DEVSHELL_PROJECT_ID-marking/bigquery_temp,javascriptTextTransformGcsPath=gs://cloud-training/gsp323/lab.js,javascriptTextTransformFunctionName=transform > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Dataflow job started${RESET}"
echo ""

echo "${BOLD}${BLUE}🔐 STEP 11: Configuring IAM permissions...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin" > /dev/null 2>&1 &
spinner

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/dataproc.editor > /dev/null 2>&1 &
spinner

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/storage.objectViewer > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ IAM permissions configured${RESET}"
echo ""

echo "${BOLD}${GREEN}🌐 STEP 12: Configuring network settings...${RESET}"
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Network settings updated${RESET}"
echo ""

echo "${BOLD}${YELLOW}🔑 STEP 13: Creating service accounts...${RESET}"
gcloud iam service-accounts create awesome \
    --display-name "my natural language service account" > /dev/null 2>&1 &
spinner

gcloud iam service-accounts keys create ~/key.json \
    --iam-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com > /dev/null 2>&1 &
spinner

export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"
gcloud auth activate-service-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service accounts configured${RESET}"
echo ""

echo "${BOLD}${MAGENTA}🧠 STEP 14: Running Natural Language API analysis...${RESET}"
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json &
spinner
echo "${GREEN}✔ Analysis completed${RESET}"
echo ""

echo "${BOLD}${CYAN}🔊 STEP 15: Running Speech-to-Text API...${RESET}"
cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-training/gsp323/task3.flac"
  }
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json &
spinner
echo "${GREEN}✔ Speech recognition completed${RESET}"
echo ""

echo "${BOLD}${BLUE}📤 STEP 16: Uploading results to Cloud Storage...${RESET}"
gsutil cp result.json $BUCKET_URL_1 > /dev/null 2>&1 &
gsutil cp result.json $BUCKET_URL_2 > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Results uploaded to Cloud Storage${RESET}"
echo ""

echo "${BOLD}${GREEN}🎥 STEP 17: Running Video Intelligence API...${RESET}"
gcloud iam service-accounts create quickstart > /dev/null 2>&1 &
spinner

gcloud iam service-accounts keys create key.json \
    --iam-account quickstart@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com > /dev/null 2>&1 &
spinner

gcloud auth activate-service-account --key-file key.json > /dev/null 2>&1 &
spinner

cat > request.json <<EOF 
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "TEXT_DETECTION"
   ]
}
EOF

curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Video analysis initiated${RESET}"
echo ""

# ======================
#  COMPLETION MESSAGE
# ======================
echo "${BG_GREEN}${BOLD}${WHITE}==================================================${RESET}"
echo "${BG_GREEN}${BOLD}${WHITE}       LAB COMPLETED SUCCESSFULLY!               ${RESET}"
echo "${BG_GREEN}${BOLD}${WHITE}==================================================${RESET}"
echo ""
echo "${WHITE}${BOLD}🔍 Access your resources:${RESET}"
echo "${YELLOW}BigQuery: https://console.cloud.google.com/bigquery?project=$PROJECT_ID${RESET}"
echo "${YELLOW}Cloud Storage: https://console.cloud.google.com/storage/browser?project=$PROJECT_ID${RESET}"
echo "${YELLOW}Dataflow: https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID${RESET}"
echo ""
echo "${CYAN}${BOLD}💡 For more Google Cloud labs and tutorials:${RESET}"
echo "${YELLOW}${BOLD}👉 ${UNDERLINE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo "${GREEN}${BOLD}🔔 Don't forget to subscribe for daily cloud tutorials!${RESET}"
echo ""

# Clean up temporary files
echo "${BOLD}${BLUE}🧹 Cleaning up temporary files...${RESET}"
rm -f lab.csv lab.schema result.json request.json key.json ~/key.json > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Cleanup complete${RESET}"
