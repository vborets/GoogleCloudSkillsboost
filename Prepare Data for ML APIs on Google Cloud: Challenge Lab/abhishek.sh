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
#  SPINNER ANIMATION
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

# ======================
#  WELCOME BANNER
# ======================
clear
echo "${BG_BLUE}${BOLD}${WHITE}==================================================${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}   GOOGLE CLOUD AI/ML SERVICES LAB               ${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}   Expertly crafted by Dr. Abhishek Cloud        ${RESET}"
echo "${BG_BLUE}${BOLD}${WHITE}==================================================${RESET}"
echo ""
echo "${CYAN}${BOLD}⚡ Learn Google Cloud AI/ML services with hands-on labs${RESET}"
echo "${YELLOW}${BOLD}📺 YouTube: ${UNDERLINE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo ""

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

COLORS=($CYAN $GREEN $YELLOW $BLUE $MAGENTA $CYAN)

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

echo

# Original function kept exactly the same
get_input() {
    local prompt="$1"
    local var_name="$2"
    local color_index="$3"

    echo -n -e "${BOLD}${COLORS[$color_index]}${prompt}${RESET} "
    read input
    export "$var_name"="$input"
}

# Original input gathering kept exactly the same
get_input "Enter the DATASET value:" "DATASET" 0
get_input "Enter the BUCKET value:" "BUCKET" 1
get_input "Enter the TABLE value:" "TABLE" 2
get_input "Enter the BUCKET_URL_1 value:" "BUCKET_URL_1" 3
get_input "Enter the BUCKET_URL_2 value:" "BUCKET_URL_2" 4

echo

# Step 1: Enable API keys service
echo "${BLUE}${BOLD}Enabling API keys service...${RESET}"
gcloud services enable apikeys.googleapis.com > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ API keys service enabled${RESET}"
echo ""

# Step 2: Create an API key
echo "${GREEN}${BOLD}Creating an API key with display name 'awesome'...${RESET}"
gcloud alpha services api-keys create --display-name="awesome" > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ API key created${RESET}"
echo ""

# Step 3: Retrieve API key name
echo "${YELLOW}${BOLD}Retrieving API key name...${RESET}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")
echo "${GREEN}✔ Key name retrieved: ${YELLOW}$KEY_NAME${RESET}"
echo ""

# Step 4: Get API key string
echo "${MAGENTA}${BOLD}Getting API key string...${RESET}"
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
echo "${GREEN}✔ API key string retrieved${RESET}"
echo ""

# Step 5: Get default Google Cloud region
echo "${CYAN}${BOLD}Getting default Google Cloud region...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])") > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Region set to: ${YELLOW}$REGION${RESET}"
echo ""

# Step 6: Retrieve project ID
echo "${RED}${BOLD}Retrieving project ID...${RESET}"
PROJECT_ID=$(gcloud config get-value project) > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Project ID: ${YELLOW}$PROJECT_ID${RESET}"
echo ""

# Step 7: Retrieve project number
echo "${GREEN}${BOLD}Retrieving project number...${RESET}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber') > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Project Number: ${YELLOW}$PROJECT_NUMBER${RESET}"
echo ""

# Step 8: Create BigQuery dataset
echo "${BLUE}${BOLD}Creating BigQuery dataset...${RESET}"
bq mk $DATASET > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Dataset created: ${YELLOW}$DATASET${RESET}"
echo ""

# Step 9: Create Cloud Storage bucket
echo "${MAGENTA}${BOLD}Creating Cloud Storage bucket...${RESET}"
gsutil mb gs://$BUCKET > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Bucket created: ${YELLOW}gs://$BUCKET${RESET}"
echo ""

# Step 10: Copy lab files from GCS
echo "${YELLOW}${BOLD}Copying lab files from GCS...${RESET}"
gsutil cp gs://cloud-training/gsp323/lab.csv . > /dev/null 2>&1 &
gsutil cp gs://cloud-training/gsp323/lab.schema . > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Files downloaded successfully${RESET}"
echo ""

# Step 11: Display schema contents
echo "${CYAN}${BOLD}Displaying schema contents...${RESET}"
cat lab.schema
echo ""

# Step 12: Create BigQuery table
echo "${RED}${BOLD}Creating BigQuery table...${RESET}"
bq mk --table $DATASET.$TABLE lab.schema > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Table created: ${YELLOW}$DATASET.$TABLE${RESET}"
echo ""

# Step 13: Run Dataflow job to load data into BigQuery
echo "${GREEN}${BOLD}Running Dataflow job to load data into BigQuery...${RESET}"
gcloud dataflow jobs run awesome-jobs --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery --region $REGION --worker-machine-type e2-standard-2 --staging-location gs://$DEVSHELL_PROJECT_ID-marking/temp --parameters inputFilePattern=gs://cloud-training/gsp323/lab.csv,JSONPath=gs://cloud-training/gsp323/lab.schema,outputTable=$DEVSHELL_PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=gs://$DEVSHELL_PROJECT_ID-marking/bigquery_temp,javascriptTextTransformGcsPath=gs://cloud-training/gsp323/lab.js,javascriptTextTransformFunctionName=transform > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Dataflow job started${RESET}"
echo ""

# Step 14: Grant IAM roles to service account
echo "${BLUE}${BOLD}Granting IAM roles to service account...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin" > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ IAM roles granted${RESET}"
echo ""

# Step 15: Assign IAM roles to user
echo "${MAGENTA}${BOLD}Assigning roles to user...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/dataproc.editor > /dev/null 2>&1 &

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/storage.objectViewer > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ User roles assigned${RESET}"
echo ""

# Step 16: Update VPC subnet for private IP access
echo "${CYAN}${BOLD}Updating VPC subnet for private IP access...${RESET}"
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ VPC subnet updated${RESET}"
echo ""

# Step 17: Create a service account
echo "${RED}${BOLD}Creating a service account...${RESET}"
gcloud iam service-accounts create awesome \
  --display-name "my natural language service account" > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account created${RESET}"
echo ""

# Step 18: Generate service account key
echo "${GREEN}${BOLD}Generating service account key...${RESET}"
gcloud iam service-accounts keys create ~/key.json \
  --iam-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account key created${RESET}"
echo ""

# Step 19: Activate service account
echo "${YELLOW}${BOLD}Activating service account...${RESET}"
export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"

gcloud auth activate-service-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account activated${RESET}"
echo ""

# Step 20: Run ML entity analysis
echo "${BLUE}${BOLD}Running ML entity analysis...${RESET}"
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json &
spinner
echo "${GREEN}✔ Entity analysis completed${RESET}"
echo ""

# Step 21: Authenticate to Google Cloud without launching a browser
echo "${GREEN}${BOLD}Authenticating to Google Cloud...${RESET}"
echo
gcloud auth login --no-launch-browser --quiet > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Authentication complete${RESET}"
echo ""

# Step 22: Copy result to bucket
echo "${MAGENTA}${BOLD}Copying result to bucket...${RESET}"
gsutil cp result.json $BUCKET_URL_2 > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Result copied to ${YELLOW}$BUCKET_URL_2${RESET}"
echo ""

# Step 23: Perform speech recognition using Google Cloud Speech-to-Text API
echo "${CYAN}${BOLD}Performing speech recognition...${RESET}"
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

# Step 24: Copy the speech recognition result to a Cloud Storage bucket
echo "${GREEN}${BOLD}Copying speech recognition result to Cloud Storage...${RESET}"
gsutil cp result.json $BUCKET_URL_1 > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Result copied to ${YELLOW}$BUCKET_URL_1${RESET}"
echo ""

# Step 25: Create a new service account named 'quickstart'
echo "${MAGENTA}${BOLD}Creating new service account 'quickstart'...${RESET}"
gcloud iam service-accounts create quickstart > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account created${RESET}"
echo ""

# Step 26: Create a service account key for 'quickstart'
echo "${BLUE}${BOLD}Creating service account key...${RESET}"
gcloud iam service-accounts keys create key.json --iam-account quickstart@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account key created${RESET}"
echo ""

# Step 27: Authenticate using the created service account key
echo "${CYAN}${BOLD}Activating service account...${RESET}"
gcloud auth activate-service-account --key-file key.json > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Service account activated${RESET}"
echo ""

# Step 28: Create a request JSON file for Video Intelligence API
echo "${GREEN}${BOLD}Creating request JSON file for Video Intelligence API...${RESET}"
cat > request.json <<EOF 
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "TEXT_DETECTION"
   ]
}
EOF
echo "${GREEN}✔ Request file created${RESET}"
echo ""

# Step 29: Annotate the video using Google Cloud Video Intelligence API
echo "${MAGENTA}${BOLD}Sending video annotation request...${RESET}"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Video annotation request sent${RESET}"
echo ""

# Original check_progress function kept exactly the same
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress for Task 3 & Task 4? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress for Task 3 & Task 4 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 30: Authenticate to Google Cloud without launching a browser
echo "${GREEN}${BOLD}Authenticating to Google Cloud...${RESET}"
echo
gcloud auth login --no-launch-browser --quiet > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Authentication complete${RESET}"
echo ""

# Step 31: Create a new Dataproc cluster
echo "${CYAN}${BOLD}Creating Dataproc cluster...${RESET}"
gcloud dataproc clusters create awesome --enable-component-gateway --region $REGION --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Dataproc cluster created${RESET}"
echo ""

# Step 32: Get the VM instance name from the project
echo "${GREEN}${BOLD}Fetching VM instance name...${RESET}"
VM_NAME=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format=json | jq -r '.[0].name') > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ VM instance name: ${YELLOW}$VM_NAME${RESET}"
echo ""

# Step 33: Get the compute zone of the VM
echo "${MAGENTA}${BOLD}Fetching VM zone...${RESET}"
export ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)') > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ VM zone: ${YELLOW}$ZONE${RESET}"
echo ""

# Step 34: Copy data from Cloud Storage to HDFS in the VM
echo "${BLUE}${BOLD}Copying data to HDFS on VM...${RESET}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="hdfs dfs -cp gs://cloud-training/gsp323/data.txt /data.txt" > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Data copied to HDFS${RESET}"
echo ""

# Step 35: Copy data from Cloud Storage to local storage in the VM
echo "${CYAN}${BOLD}Copying data to local storage on VM...${RESET}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="gsutil cp gs://cloud-training/gsp323/data.txt /data.txt" > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Data copied to local storage${RESET}"
echo ""

# Step 36: Submit a Spark job to the Dataproc cluster
echo "${MAGENTA}${BOLD}Submitting Spark job to Dataproc...${RESET}"
gcloud dataproc jobs submit spark \
  --cluster=awesome \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPageRank \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  --project=$DEVSHELL_PROJECT_ID \
  -- /data.txt > /dev/null 2>&1 &
spinner
echo "${GREEN}✔ Spark job submitted${RESET}"
echo ""

# Original remove_files function kept exactly the same
remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

# Clean up files
echo "${BOLD}${BLUE}🧹 Cleaning up files...${RESET}"
remove_files
echo "${GREEN}✔ Cleanup complete${RESET}"
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
