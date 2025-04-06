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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Random Thank You Messages
THANK_YOU_MESSAGES=(
    "Thanks for providing the details!"
    "Appreciate your input!"
    "Your details have been recorded!"
    "Thanks for your response!"
    "Your input is valuable, thank you!"
)

# Pick a random thank you message
RANDOM_THANK_YOU=${THANK_YOU_MESSAGES[$RANDOM % ${#THANK_YOU_MESSAGES[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${CYAN}${BOLD}Welcome to Dr. Abhishek Cloud Tutorials${RESET}"
echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

set_cloudshell_env() {
    echo
    echo -n "${CYAN}${BOLD}Enter Repository Name: ${RESET}"
    read REPO
    echo -n "${MAGENTA}${BOLD}Enter Docker Image: ${RESET}"
    read DCKR_IMG
    echo -n "${YELLOW}${BOLD}Enter Tag Name: ${RESET}"
    read TAG

    export REPO="$REPO"
    export DCKR_IMG="$DCKR_IMG"
    export TAG="$TAG"

    echo

    echo "${RANDOM_TEXT_COLOR}${BOLD}$RANDOM_THANK_YOU${RESET}"

    echo

}

set_cloudshell_env

# Step 1: Fetching region and zone details...
echo "${CYAN}${BOLD}Fetching region and zone details...${RESET}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Sourcing setup script...
echo "${MAGENTA}${BOLD}Sourcing setup script...${RESET}"
source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)

# Step 3: Downloading and extracting application...
echo "${GREEN}${BOLD}Downloading and extracting application...${RESET}"
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app

# Step 4: Creating Dockerfile...
echo "${YELLOW}${BOLD}Creating Dockerfile...${RESET}"
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# Step 5: Building Docker image...
echo "${BLUE}${BOLD}Building Docker image...${RESET}"
docker build -t $DCKR_IMG:$TAG .

# Step 6: Executing Step 1 script...
echo "${MAGENTA}${BOLD}Executing Step 1 script...${RESET}"
cd ..
./step1_v2.sh

# Step 7: Running Docker container...
echo "${CYAN}${BOLD}Running Docker container...${RESET}"
cd valkyrie-app
docker run -d -p 8080:8080 $DCKR_IMG:$TAG

# Step 8: Executing Step 2 script...
echo "${MAGENTA}${BOLD}Executing Step 2 script...${RESET}"
cd ..
./step2_v2.sh

cd valkyrie-app

# Step 9: Creating Artifact Repository...
echo "${YELLOW}${BOLD}Creating Artifact Repository...${RESET}"
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="awesome lab" \
    --async

# Step 10: Configuring Docker authentication...
echo "${BLUE}${BOLD}Configuring Docker authentication...${RESET}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

sleep 30

# Step 11: Tagging and pushing Docker image...
echo "${CYAN}${BOLD}Tagging and pushing Docker image...${RESET}"

Image_ID=$(docker images --format='{{.ID}}')

docker tag $Image_ID $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

# Step 12: Updating Kubernetes deployment...
echo "${GREEN}${BOLD}Updating Kubernetes deployment...${RESET}"
sed -i s#IMAGE_HERE#$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG#g k8s/deployment.yaml

# Step 13: Configuring Kubernetes cluster...
echo "${YELLOW}${BOLD}Configuring Kubernetes cluster...${RESET}"
gcloud container clusters get-credentials valkyrie-dev --zone $ZONE

# Step 14: Deploying application to Kubernetes...
echo "${BLUE}${BOLD}Deploying application to Kubernetes...${RESET}"
kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml

echo

# Simple completion message
echo "${GREEN}${BOLD}Congrats Now subscribe to the channel!${RESET}"

echo -e "\n"  # Adding one blank line

cd

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

remove_files

echo "${CYAN}${BOLD}Subscribe to our YouTube channel for more cloud tutorials:${RESET}"
echo "${YELLOW}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
