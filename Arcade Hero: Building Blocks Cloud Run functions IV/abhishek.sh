#!/bin/bash

# Enhanced Color Definitions
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36;1m"
YELLOW="\033[33;1m"
BLUE="\033[34;1m"
GREEN="\033[32;1m"
MAGENTA="\033[35;1m"
WHITE="\033[37;1m"

# Welcome Banner
echo -e "${BLUE}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║           Dr. Abhishek Cloud Tutorials            ║"
echo "║                                                   ║"
echo "║  Comprehensive GCP Learning Resources             ║"
echo "║  YouTube: https://youtube.com/@drabhishek.5460    ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${RESET}"

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

echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════╗"
echo "║                STARTING EXECUTION               ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Step 1: Set environment variables
echo -e "${CYAN}${BOLD}🔧 Setting environment variables...${RESET}"
echo -n "  - Getting project ID..."
export PROJECT_ID=$(gcloud config get-value project) &
spinner
echo -e " ${GREEN}✓${RESET}"
echo -e "  ${WHITE}Project ID: ${BOLD}$PROJECT_ID${RESET}"

export REGION="us-central1"
export FUNCTION_NAME="cf-nodejs"
echo -e "  ${WHITE}Region: ${BOLD}$REGION${RESET}"
echo -e "  ${WHITE}Function Name: ${BOLD}$FUNCTION_NAME${RESET}"

# Step 2: Create source code for the Cloud Function
echo -e "\n${YELLOW}${BOLD}📝 Creating sample Node.js function...${RESET}"
mkdir -p cloud-function
echo -n "  - Writing index.js..."
cat > cloud-function/index.js <<EOF
exports.helloWorld = (req, res) => {
  res.send('Hello from Cloud Function!');
};
EOF &
spinner
echo -e " ${GREEN}✓${RESET}"

echo -n "  - Writing package.json..."
cat > cloud-function/package.json <<EOF
{
  "name": "cf-nodejs",
  "version": "1.0.0",
  "main": "index.js"
}
EOF &
spinner
echo -e " ${GREEN}✓${RESET}"

# Step 3: Deploy the Cloud Function (2nd Gen)
echo -e "\n${BLUE}${BOLD}🚀 Deploying Cloud Function: ${FUNCTION_NAME}...${RESET}"
echo -e "${WHITE}This may take 1-2 minutes. Please wait...${RESET}"
gcloud functions deploy ${FUNCTION_NAME} \
  --gen2 \
  --runtime=nodejs20 \
  --region=${REGION} \
  --source=cloud-function \
  --entry-point=helloWorld \
  --trigger-http \
  --max-instances=5 \
  --allow-unauthenticated > /dev/null 2>&1 &
spinner
echo -e " ${GREEN}✓${RESET}"

echo -e "\n${GREEN}${BOLD}✅ Deployment complete!${RESET}"

# Completion Message
echo -e "\n${MAGENTA}${BOLD}╔═══════════════════════════════════════════════════╗"
echo "║                 THANK YOU!                  ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "${WHITE}For more GCP tutorials and labs:${RESET}"
echo -e "${BLUE}${BOLD}https://youtube.com/@drabhishek.5460${RESET}"
echo -e "\n${YELLOW}${BOLD}⚠️ Remember to clean up resources when finished:${RESET}"
echo -e "${WHITE}gcloud functions delete ${FUNCTION_NAME} --region=${REGION}${RESET}"

# Cleanup temporary files
echo -e "\n${CYAN}${BOLD}🧹 Cleaning up temporary files...${RESET}"
cd ~
remove_files() {
  for file in *; do
    if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
      if [[ -f "$file" ]]; then
        rm "$file"
        echo "  - Removed: $file"
      fi
    fi
  done
}
remove_files
