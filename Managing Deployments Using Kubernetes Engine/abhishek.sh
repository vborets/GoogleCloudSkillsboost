#!/bin/bash

# Enhanced Color Definitions
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

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

# Header Section
clear
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}        WELCOME TO DR ABHISHEK CLOUD TUTORIAL              ${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}          Expert Tutorial by Dr. Abhishek              ${RESET}"
echo "${YELLOW}For more Kubernetes tutorials, visit: https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${BLUE}${BOLD}⚡ Initializing Kubernetes Cluster Setup...${RESET}"
echo

# User Input
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ CLUSTER CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}${BOLD}Enter the ZONE (e.g., us-central1-a): ${RESET}" ZONE
gcloud config set compute/zone $ZONE
echo "${GREEN}✅ Zone configured to ${BOLD}$ZONE${RESET}"
echo

# Setup Kubernetes Resources
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ KUBERNETES RESOURCE SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Downloading Kubernetes configuration files...${RESET}"
gsutil -m cp -r gs://spls/gsp053/orchestrate-with-kubernetes .
cd orchestrate-with-kubernetes/kubernetes
echo "${GREEN}✅ Files downloaded successfully!${RESET}"
echo

# Cluster Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ CLUSTER CREATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating Kubernetes cluster 'bootcamp'...${RESET}"
gcloud container clusters create bootcamp \
        --machine-type e2-small \
        --num-nodes 3 \
        --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
echo "${GREEN}✅ Cluster created successfully!${RESET}"
echo

# Auth Deployment
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ AUTH DEPLOYMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Configuring auth deployment...${RESET}"
sed -i 's/image: "kelseyhightower\/auth:2.0.0"/image: "kelseyhightower\/auth:1.0.0"/' deployments/auth.yaml
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml
echo "${GREEN}✅ Auth deployment and service created!${RESET}"
echo

# Hello Deployment
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ HELLO DEPLOYMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating hello deployment and service...${RESET}"
kubectl create -f deployments/hello.yaml
kubectl create -f services/hello.yaml
echo "${GREEN}✅ Hello deployment and service created!${RESET}"
echo

# Frontend Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FRONTEND CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Setting up frontend components...${RESET}"
kubectl create secret generic tls-certs --from-file tls/
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf
kubectl create -f deployments/frontend.yaml
kubectl create -f services/frontend.yaml
echo "${GREEN}✅ Frontend components deployed!${RESET}"
echo

# Scaling Demonstration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ SCALING DEMONSTRATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Scaling hello deployment to 5 replicas...${RESET}"
sleep 10
kubectl scale deployment hello --replicas=5
echo "${GREEN}Current pod count: $(kubectl get pods | grep hello- | wc -l)${RESET}"

echo "${YELLOW}Scaling back to 3 replicas...${RESET}"
kubectl scale deployment hello --replicas=3
echo "${GREEN}Current pod count: $(kubectl get pods | grep hello- | wc -l)${RESET}"
echo

# Rolling Updates
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ROLLING UPDATES ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Preparing for rolling update...${RESET}"
sed -i 's/image: "kelseyhightower\/auth:1.0.0"/image: "kelseyhightower\/auth:2.0.0"/' deployments/hello.yaml
echo "${GREEN}✅ Image version updated in deployment!${RESET}"

echo "${YELLOW}Checking rollout history...${RESET}"
kubectl rollout history deployment/hello

echo "${YELLOW}Resuming rollout...${RESET}"
kubectl rollout resume deployment/hello
kubectl rollout status deployment/hello

echo "${YELLOW}Rolling back deployment...${RESET}"
kubectl rollout undo deployment/hello
echo "${GREEN}✅ Rollback completed!${RESET}"
echo

# Canary Deployment
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ CANARY DEPLOYMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating hello-canary deployment...${RESET}"
kubectl create -f deployments/hello-canary.yaml
echo "${GREEN}✅ Canary deployment created!${RESET}"
echo

# Verification
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ VERIFICATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Current deployments:${RESET}"
kubectl get deployments
echo
echo "${YELLOW}Current pods and images:${RESET}"
kubectl get pods -o jsonpath --template='{range .items[*]}{.metadata.name}{"\t"}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
echo

# Completion Message
echo "${BG_GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}          LAB COMPLETED!                ${RESET}"
echo "${BG_GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}🙏 Thank you for following Dr. Abhishek's tutorial!${RESET}"
echo "${YELLOW}${BOLD}📺 Subscribe for more Kubernetes content:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
echo "${MAGENTA}${BOLD}🚢 Happy container orchestration with Kubernetes!${RESET}"
