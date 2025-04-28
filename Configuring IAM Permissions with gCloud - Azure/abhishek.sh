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

BOLD=`tput bold`
RESET=`tput sgr0`

clear


echo "${BLUE}${BOLD}====================================================================${RESET}"
echo "${BLUE}${BOLD}                  Dr. Abhishek Cloud Tutorials                     ${RESET}"
echo "${BLUE}${BOLD}====================================================================${RESET}"
echo
echo "${GREEN}${BOLD}Starting Google Cloud IAM and Compute Engine Lab${RESET}"
echo

# Check gcloud version
echo "${CYAN}${BOLD}Checking gcloud version...${RESET}"
gcloud --version

# Authenticate
echo "${CYAN}${BOLD}Authenticating with Google Cloud...${RESET}"
gcloud auth login

# Set project and zone
echo "${CYAN}${BOLD}Setting up project configuration...${RESET}"
export PROJECT_ID=$(gcloud config get-value core/project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${YELLOW}Current zone: ${ZONE}${RESET}"
echo "${YELLOW}Current region: ${REGION}${RESET}"

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Create first VM instance
echo "${CYAN}${BOLD}Creating lab-1 VM instance...${RESET}"
gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2

# Show current configuration
echo "${CYAN}${BOLD}Current configuration:${RESET}"
gcloud config list

# Zone selection
echo "${CYAN}${BOLD}Available zones in region ${REGION}:${RESET}"
gcloud compute zones list --filter="region:($REGION)" --format="value(name)" | while read -r zone; do
  echo "${YELLOW}${zone}${RESET}"
done

read -e -p "${YELLOW}${BOLD}Enter the ZONE: ${RESET}" ZONE
gcloud config set compute/zone $ZONE
echo "${GREEN}Zone updated to: ${ZONE}${RESET}"

# Show updated configuration
echo "${CYAN}${BOLD}Updated configuration:${RESET}"
gcloud config list

# IAM configuration
echo "${CYAN}${BOLD}Opening IAM console for manual verification...${RESET}"
echo "${BLUE}Please visit: https://console.cloud.google.com/iam-admin/iam?project=${PROJECT_ID}${RESET}"
echo

while true; do
    read -p "${YELLOW}${BOLD}Do you want to proceed? (Y/n): ${RESET}" confirm
    case "$confirm" in
        [Yy]) 
            echo "${BLUE}Continuing with the lab...${RESET}"
            break
            ;;
        [Nn]|"") 
            echo "${RED}Operation canceled.${RESET}"
            exit 1
            ;;
        *) 
            echo "${RED}Invalid input. Please enter Y or N.${RESET}" 
            ;;
    esac
done

# IAM roles inspection
echo "${CYAN}${BOLD}Listing available IAM roles...${RESET}"
gcloud iam roles list | grep "name:"

echo "${CYAN}${BOLD}Inspecting compute.instanceAdmin role...${RESET}"
gcloud iam roles describe roles/compute.instanceAdmin

# User and project configuration
read -e -p "${YELLOW}${BOLD}Enter the USER2: ${RESET}" USER2
read -e -p "${YELLOW}${BOLD}Enter the PROJECT_ID2: ${RESET}" PROJECT_ID2
read -e -p "${YELLOW}${BOLD}Enter the VM ZONE: ${RESET}" ZONE

# Configure user2 environment
echo "${CYAN}${BOLD}Configuring user2 environment...${RESET}"
gcloud config configurations activate user2
echo "export PROJECTID2=$PROJECT_ID2" >> ~/.bashrc
. ~/.bashrc

# Install required packages
echo "${CYAN}${BOLD}Installing required packages...${RESET}"
sudo yum -y install epel-release
sudo yum -y install jq

# Configure user environment
echo "export USERID2=$USER2" >> ~/.bashrc
. ~/.bashrc

# Assign IAM roles
echo "${CYAN}${BOLD}Assigning IAM roles to user...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/viewer

# Switch to user2 config
gcloud config configurations activate user2
gcloud config set project $PROJECT_ID2
gcloud compute instances list

# Create custom devops role
echo "${CYAN}${BOLD}Creating custom devops role...${RESET}"
gcloud config configurations activate default
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"

# Assign additional roles
echo "${CYAN}${BOLD}Assigning additional roles to user...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member user:$USER2 --role=projects/$PROJECT_ID2/roles/devops

# Create lab-2 instance
echo "${CYAN}${BOLD}Creating lab-2 VM instance...${RESET}"
gcloud config configurations activate user2
gcloud compute instances create lab-2 --zone $ZONE
gcloud compute instances list

# Service account setup
echo "${CYAN}${BOLD}Setting up service account...${RESET}"
gcloud config configurations activate default
gcloud config set project $PROJECT_ID2
gcloud iam service-accounts create devops --display-name devops
gcloud iam service-accounts list --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

# Assign roles to service account
echo "${CYAN}${BOLD}Assigning roles to service account...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT_ID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin

# Create lab-3 instance with service account
echo "${CYAN}${BOLD}Creating lab-3 VM instance with service account...${RESET}"
export ZONE=$ZONE
gcloud compute instances create lab-3 --zone $ZONE --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"

# Completion message
echo
echo "${GREEN}${BOLD}====================================================================${RESET}"
echo "${GREEN}${BOLD}               LAB EXECUTION COMPLETED SUCCESSFULLY               ${RESET}"
echo "${GREEN}${BOLD}====================================================================${RESET}"
echo
echo "${BLUE}${BOLD}Thank you for using Dr. Abhishek Cloud Tutorials!${RESET}"
echo
echo "${YELLOW}${BOLD}For more cloud tutorials and labs, visit our YouTube channels:${RESET}"
echo "${CYAN}Do like share & Subscribe${RESET}"
echo "${CYAN}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
