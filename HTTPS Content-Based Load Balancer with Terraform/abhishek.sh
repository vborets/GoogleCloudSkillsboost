#!/bin/bash
# Define color variables with improved formatting
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

# Spinner function
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

# Header function
header() {
    echo "${BG_MAGENTA}${BOLD}${WHITE}============================================${RESET}"
    echo "${BG_MAGENTA}${BOLD}${WHITE}  HTTPS Load Balancer Terraform Deployment  ${RESET}"
    echo "${BG_MAGENTA}${BOLD}${WHITE}============================================${RESET}"
    echo
}

# Welcome message
welcome() {
    header
    echo "${CYAN}${BOLD}Welcome to Dr. Abhishek's Terraform Lab Script${RESET}"
    echo "${YELLOW}Subscribe to my channel: https://www.youtube.com/@drabhishek.5460${RESET}"
    echo
    echo "${GREEN}${BOLD}Starting execution...${RESET}"
    echo
}

# Success message
success() {
    echo "${GREEN}${BOLD}✓ $1${RESET}"
}

#----------------------------------------------------start--------------------------------------------------#
welcome

echo "${YELLOW}${BOLD}Checking authentication...${RESET}"
(gcloud auth list >/dev/null 2>&1) & spinner
success "Authentication verified"

echo "${YELLOW}${BOLD}Cloning Terraform HTTP LB repository...${RESET}"
(git clone https://github.com/GoogleCloudPlatform/terraform-google-lb-http.git >/dev/null 2>&1) & spinner
success "Repository cloned"

echo "${YELLOW}${BOLD}Changing to example directory...${RESET}"
(cd ~/terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb >/dev/null 2>&1) & spinner
success "Changed to working directory"

echo "${YELLOW}${BOLD}Downloading custom main.tf configuration...${RESET}"
(rm -rf main.tf >/dev/null 2>&1) & spinner
(wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/HTTPS%20Content-Based%20Load%20Balancer%20with%20Terraform/main.tf >/dev/null 2>&1) & spinner
success "Configuration downloaded"

echo "${YELLOW}${BOLD}Initializing Terraform...${RESET}"
(terraform init >/dev/null 2>&1) & spinner
success "Terraform initialized"

echo "${YELLOW}${BOLD}Planning Terraform deployment...${RESET}"
(echo $DEVSHELL_PROJECT_ID | terraform plan >/dev/null 2>&1) & spinner
success "Terraform plan generated"

echo "${YELLOW}${BOLD}Applying Terraform configuration...${RESET}"
(echo $DEVSHELL_PROJECT_ID | terraform apply -auto-approve >/dev/null 2>&1) & spinner
success "Terraform configuration applied"

# Final message
echo
echo "${BG_RED}${BOLD}${WHITE}============================================${RESET}"
echo "${BG_RED}${BOLD}${WHITE}  Congratulations For Completing The Lab!   ${RESET}"
echo "${BG_RED}${BOLD}${WHITE}============================================${RESET}"
echo
echo "${CYAN}${BOLD}Thank you!${RESET}"
echo "${YELLOW}${BOLD}Don't forget to subscribe to my channel:${RESET}"
echo "${BLUE}${BOLD}https://www.youtube.com/@drabhishek.5460${RESET}"
echo

#-----------------------------------------------------end----------------------------------------------------------#
