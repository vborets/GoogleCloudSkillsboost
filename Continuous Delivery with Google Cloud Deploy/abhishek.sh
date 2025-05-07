
#!/bin/bash
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

clear

# Welcome Banner
echo "${BLUE_TEXT}${BOLD_TEXT}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║           Dr. Abhishek Cloud Tutorials            ║"
echo "║                                                   ║"
echo "║  Comprehensive GCP Learning Resources             ║"
echo "║  YouTube: https://youtube.com/@drabhishek.5460    ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo "${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔═══════════════════════════════════════════════════╗"
echo "║                INITIATING SCRIPT                ║"
echo "╚═══════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo -n "${YELLOW_TEXT}${BOLD_TEXT}🔍 Verifying active Google Cloud account...${RESET_FORMAT}"
(gcloud auth list > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
gcloud auth list

echo
echo -n "${GREEN_TEXT}${BOLD_TEXT}🌍 Determining default compute zone...${RESET_FORMAT}"
(export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
echo "${WHITE_TEXT}Zone set to: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"

echo
echo -n "${GREEN_TEXT}${BOLD_TEXT}🌎 Determining default compute region...${RESET_FORMAT}"
(export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
echo "${WHITE_TEXT}Region set to: ${BOLD_TEXT}$REGION${RESET_FORMAT}"

echo
echo -n "${GREEN_TEXT}${BOLD_TEXT}🆔 Fetching project ID...${RESET_FORMAT}"
(export PROJECT_ID=$(gcloud config get-value project)) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
echo "${WHITE_TEXT}Project ID set to: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo
echo -n "${BLUE_TEXT}${BOLD_TEXT}⚙️ Configuring default zone ($ZONE)...${RESET_FORMAT}"
(gcloud config set compute/zone "$ZONE" > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo -n "${BLUE_TEXT}${BOLD_TEXT}⚙️ Configuring default region ($REGION)...${RESET_FORMAT}"
(gcloud config set compute/region "$REGION" > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo -n "${YELLOW_TEXT}${BOLD_TEXT}📥 Downloading demo application...${RESET_FORMAT}"
(gsutil cp gs://spls/gsp449/gke-cloud-sql-postgres-demo.tar.gz . > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo -n "${YELLOW_TEXT}${BOLD_TEXT}📦 Extracting archive...${RESET_FORMAT}"
(tar -xzvf gke-cloud-sql-postgres-demo.tar.gz > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo -n "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory...${RESET_FORMAT}"
(cd gke-cloud-sql-postgres-demo) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo -n "${GREEN_TEXT}${BOLD_TEXT}📧 Retrieving admin email...${RESET_FORMAT}"
(PG_EMAIL=$(gcloud config get-value account)) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
echo "${WHITE_TEXT}PostgreSQL admin email: ${BOLD_TEXT}$PG_EMAIL${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Starting demo application setup..."
echo "This may take several minutes. Please wait...${RESET_FORMAT}"
./create.sh dbadmin $PG_EMAIL

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for resources to initialize...${RESET_FORMAT}"
for i in $(seq 10 -1 1); do
  echo -ne "${BLUE_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Resources initialized${RESET_FORMAT}"

echo
echo -n "${YELLOW_TEXT}${BOLD_TEXT}🔍 Identifying application Pod...${RESET_FORMAT}"
(POD_ID=$(kubectl --namespace default get pods -o name | cut -d '/' -f 2)) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"
echo "${WHITE_TEXT}Application Pod ID: ${BOLD_TEXT}$POD_ID${RESET_FORMAT}"

echo
echo -n "${GREEN_TEXT}${BOLD_TEXT}🌐 Exposing application as LoadBalancer...${RESET_FORMAT}"
(kubectl expose pod $POD_ID --port=80 --type=LoadBalancer > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📋 Current services:${RESET_FORMAT}"
kubectl get svc

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}╔═══════════════════════════════════════════════════╗"
echo "║                 THANK YOU!                  ║"
echo "╚═══════════════════════════════════════════════════╝${RESET_FORMAT}"
echo "${WHITE_TEXT}For more GCP tutorials and labs, subscribe to:"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}https://youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Lab completed successfully!${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Remember to clean up resources when finished.${RESET_FORMAT}"
