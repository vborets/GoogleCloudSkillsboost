#!/bin/bash

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


clear
echo "${CYAN}${BOLD}"
echo "**********************************************************************"
echo "* Welcome to Optimizing Cost with Google Cloud Storage Lab                      *"
echo "*                                                                    *"
echo "* Brought to you by Dr. Abhishek Cloud Tutorials                     *"
echo "* Please like, share and subscribe:                                  *"
echo "* https://www.youtube.com/@drabhishek.5460/videos                    *"
echo "**********************************************************************"
echo "${RESET}"

# Task 1: Enable APIs and download source code
echo "${GREEN}${BOLD}Task 1: Enabling APIs and downloading source code...${RESET}"
gcloud services enable cloudscheduler.googleapis.com
gcloud storage cp -r gs://spls/gsp649/* . && cd gcf-automated-resource-cleanup/
export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
WORKDIR=$(pwd)
sudo apt-get update && sudo apt-get install apache2-utils -y

# Task 2: Create Cloud Storage buckets
echo "${GREEN}${BOLD}Task 2: Creating Cloud Storage buckets...${RESET}"
cd $WORKDIR/migrate-storage
gcloud storage buckets create gs://${PROJECT_ID}-serving-bucket -l us-east4
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket
gcloud storage cp $WORKDIR/migrate-storage/testfile.txt gs://${PROJECT_ID}-serving-bucket
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket/testfile.txt
curl http://storage.googleapis.com/${PROJECT_ID}-serving-bucket/testfile.txt
gcloud storage buckets create gs://${PROJECT_ID}-idle-bucket -l us-east4
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket

# Task 3: Monitoring dashboard instructions
echo "${YELLOW}${BOLD}Task 3: Please manually create the Monitoring Dashboard:${RESET}"
echo "1. Go to Navigation Menu > Observability > Monitoring"
echo "2. Click Dashboards > Create Custom Dashboard"
echo "3. Name it 'Bucket Usage'"
echo "4. Add a Line widget titled 'Bucket Access'"
echo "5. Select GCS Bucket > Api > Request count metric"
echo "6. Group by bucket_name and filter by method=ReadObject"

# Task 4: Generate load
echo "${GREEN}${BOLD}Task 4: Generating load on serving bucket...${RESET}"
ab -n 10000 http://storage.googleapis.com/$PROJECT_ID-serving-bucket/testfile.txt

# Task 5: Deploy Cloud Run function
echo "${GREEN}${BOLD}Task 5: Deploying Cloud Run function...${RESET}"
cat $WORKDIR/migrate-storage/main.py | grep "migrate_storage(" -A 15
sed -i "s/<project-id>/$PROJECT_ID/" $WORKDIR/migrate-storage/main.py
gcloud services disable cloudfunctions.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
gcloud functions deploy migrate_storage --gen2 --trigger-http --runtime=python39 --region us-east4
export FUNCTION_URL=$(gcloud functions describe migrate_storage --format=json --region us-east4 | jq -r '.url')

# Task 6: Test alerting automation
echo "${GREEN}${BOLD}Task 6: Testing alerting automation...${RESET}"
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket
sed -i "s/\\\$IDLE_BUCKET_NAME/$IDLE_BUCKET_NAME/" $WORKDIR/migrate-storage/incident.json
envsubst < $WORKDIR/migrate-storage/incident.json | curl -X POST -H "Content-Type: application/json" $FUNCTION_URL -d @-
gsutil defstorageclass get gs://$PROJECT_ID-idle-bucket

# Completion message
echo "${CYAN}${BOLD}"
echo "**********************************************************************"
echo "* Lab completed successfully!                                        *"
echo "*                                                                    *"
echo "* For more cloud tutorials, subscribe to:                            *"
echo "* Dr. Abhishek's YouTube Channel                                     *"
echo "* https://www.youtube.com/@drabhishek.5460/videos                    *"
echo "**********************************************************************"
echo "${RESET}"
