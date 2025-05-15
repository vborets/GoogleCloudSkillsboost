
#!/bin/bash

# Define color variables
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

# Welcome message
echo "${BG_MAGENTA}${BOLD}Welcome to Dr. Abhishek's Cloud Tutorials${RESET}"
echo

# Function to validate email format
validate_email() {
  local email=$1
  if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt user for GitHub email
echo "${CYAN}${BOLD}Step 1: GitHub Configuration${RESET}"
while true; do
  read -p "${YELLOW}Please enter your GitHub email address: ${RESET}" USER_EMAIL
  if validate_email "$USER_EMAIL"; then
    break
  else
    echo "${RED}${BOLD}Invalid email format. Please try again.${RESET}"
  fi
done

# Get region and project info
echo
echo "${CYAN}${BOLD}Step 2: Setting up GCP Environment${RESET}"
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud config set compute/region $REGION

echo "${GREEN}${BOLD}✅ Using Region: ${WHITE}${BOLD}$REGION${RESET}"
echo "${GREEN}${BOLD}✅ Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET}"
echo "${GREEN}${BOLD}✅ Project Number: ${WHITE}${BOLD}$PROJECT_NUMBER${RESET}"

# Enable required services
echo
echo "${BLUE}${BOLD}Enabling required GCP services...${RESET}"
gcloud services enable container.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  containeranalysis.googleapis.com

# Create Artifact Registry repository
echo
echo "${BLUE}${BOLD}Creating Artifact Registry repository...${RESET}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

# Create GKE cluster
echo
echo "${BLUE}${BOLD}Creating GKE cluster...${RESET}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

# GitHub authentication
echo
echo "${CYAN}${BOLD}Step 3: GitHub Setup${RESET}"
echo "${YELLOW}Please authenticate with GitHub when prompted...${RESET}"
curl -sS https://webi.sh/gh | sh
gh auth login
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

echo "${GREEN}${BOLD}✅ GitHub Username: ${WHITE}${BOLD}$GITHUB_USERNAME${RESET}"
echo "${GREEN}${BOLD}✅ User Email: ${WHITE}${BOLD}$USER_EMAIL${RESET}"

# Create GitHub repositories
echo
echo "${BLUE}${BOLD}Creating GitHub repositories...${RESET}"
gh repo create hello-cloudbuild-app --private
gh repo create hello-cloudbuild-env --private

# Set up hello-cloudbuild-app
echo
echo "${CYAN}${BOLD}Step 4: Setting up hello-cloudbuild-app${RESET}"
cd ~
mkdir hello-cloudbuild-app
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app
cd ~/hello-cloudbuild-app

# Update region in configuration files
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

# Initialize git repository
git init
git config credential.helper gcloud.sh
git remote add google "https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app"
git branch -m master
git add . && git commit -m "initial commit"

# Build and push container image
echo
echo "${BLUE}${BOLD}Building and pushing container image...${RESET}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

# Push to GitHub
echo
echo "${BLUE}${BOLD}Pushing to GitHub repository...${RESET}"
git add .
git commit -m "Type Any Commit Message here"
git push google master

# Set up SSH key for GitHub
echo
echo "${CYAN}${BOLD}Step 5: Configuring SSH Access${RESET}"
cd ~
mkdir -p workingdir
cd workingdir
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"

# Store SSH key in Secret Manager
echo
echo "${BLUE}${BOLD}Storing SSH key in Secret Manager...${RESET}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"
gcloud secrets versions add ssh_key_secret --data-file=id_github

# Add SSH key to GitHub
echo
echo "${BLUE}${BOLD}Adding SSH key to GitHub...${RESET}"
GITHUB_TOKEN=$(gh auth token)
SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)

gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false

rm id_github*

# Set up IAM permissions
echo
echo "${CYAN}${BOLD}Step 6: Configuring IAM Permissions${RESET}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/container.developer"

# Set up hello-cloudbuild-env
echo
echo "${CYAN}${BOLD}Step 7: Setting up hello-cloudbuild-env${RESET}"
cd ~
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env
cd hello-cloudbuild-env

# Update region in configuration files
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

# Configure SSH known hosts
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

# Initialize git repository
git init
git config credential.helper gcloud.sh
git remote add google "https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env"
git branch -m master
git add . && git commit -m "initial commit"
git push google master

# Set up production branch
echo
echo "${BLUE}${BOLD}Configuring production branch...${RESET}"
git checkout -b production
rm cloudbuild.yaml
curl -LO https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/env-cloudbuild.yaml
mv env-cloudbuild.yaml cloudbuild.yaml

# Update configuration files
sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add .
git commit -m "Create cloudbuild.yaml for deployment"

# Set up candidate branch
echo
echo "${BLUE}${BOLD}Configuring candidate branch...${RESET}"
git checkout -b candidate
git push google production
git push google candidate

# Final configuration for hello-cloudbuild-app
echo
echo "${CYAN}${BOLD}Step 8: Finalizing Configuration${RESET}"
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git add .
git commit -m "Adding known_host file."
git push google master

rm cloudbuild.yaml
curl -LO https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/app-cloudbuild.yaml
mv app-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add cloudbuild.yaml
git commit -m "Trigger CD pipeline"
git push google master

# Completion message
echo
echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
echo
echo "${MAGENTA}${BOLD}If you found this helpful, subscribe to my channel:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
