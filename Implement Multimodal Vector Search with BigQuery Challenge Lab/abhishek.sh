#!/bin/bash



clear
echo -e "\n\033[1;34m============================================\033[0m"
echo -e "   👋  WELCOME TO \033[1;32mDR ABHISHEK CLOUD TUTORIALS\033[0m  "
echo -e "         Your Cloud Learning Destination"
echo -e "\033[1;34m============================================\033[0m"
echo -e "   ▶️  Don't forget to \033[1;31mSUBSCRIBE\033[0m ❤️"
echo -e "   🔗 Channel: \033[1;36mhttps://www.youtube.com/@drabhishek.5460/videos\033[0m"
echo -e "\033[1;34m============================================\033[0m\n"

# Spinner Function for Visual Appeal
spinner() {
  local pid=$1
  local delay=0.1
  local spin='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for i in {0..3}; do
      echo -ne "\r⏳ Loading... ${spin:$i:1} "
      sleep $delay
    done
  done
  echo -ne "\r✅  Ready!             \n"
}

# Simulate a short loading delay
( sleep 3 ) & spinner $!

# ======================
# Begin Main Script Tasks
# ======================

gcloud auth list
gcloud services enable aiplatform.googleapis.com

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

bq mk --connection --location=$REGION --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE vector_conn

SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.$REGION.vector_conn | jq -r '.cloudResource.serviceAccountId')
echo "Service Account: $SERVICE_ACCOUNT"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.dataOwner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"

sleep 20

# (… rest of your BigQuery tasks …)

echo -e "\n\033[1;32m🎯 Tutorial Completed Successfully!\033[0m"
echo -e "👉 Don’t forget to Subscribe: \033[1;36mhttps://www.youtube.com/@drabhishek.5460/videos\033[0m\n"
