#!/bin/bash

# ==============================================
# GKE Tracing Demo Setup
# Welcome to Dr. Abhishek Cloud Tutorials!
# YouTube: https://www.youtube.com/@drabhishek.5460/videos
# ==============================================

# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# ASCII Art Banner
echo "                                                                               
  ____  _       _     _           _    _           _       _     _   
 |  _ \(_)     | |   | |         | |  | |         | |     | |   | |  
 | |_) |_  __ _| |__ | |__   ___ | | _| | ___  ___| |_ ___| |__ | |_ 
 |  _ <| |/ _\` | '_ \| '_ \/ _ \| |/ / |/ _ \/ __| __/ __| '_ \| __|
 | |_) | | (_| | | | | | | | (_) |   <| |  __/\__ \ || (__| | | | |_ 
 |____/|_|\__, |_| |_|_| |_|\___/|_|\_\_|\___||___/\__\___|_| |_|\__|
           __/ |                                                     
          |___/                                                      
"

echo "=================================================================="
echo "           WELCOME TO DR. ABHISHEK CLOUD TUTORIALS!"
echo "=================================================================="
echo " YouTube Channel: https://www.youtube.com/@drabhishek.5460/videos"
echo "=================================================================="
echo "    SUBSCRIBE for more GKE and Observability tutorials!"
echo "=================================================================="
echo ""

# Function to display progress
progress() {
    echo "${GREEN}✅${RESET} ${BOLD}$1${RESET}"
    sleep 2
}

# Function to handle errors
handle_error() {
    echo "${RED}❌ Error: $1${RESET}"
    sleep 2
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo "${GREEN}✅ Success${RESET}"
    else
        handle_error "$2"
    fi
}

# Get zone input
echo "${BOLD}Please set the below values correctly${RESET}"
read -p "${YELLOW}${BOLD}Enter the ZONE (e.g., us-central1-a): ${RESET}" ZONE

if [ -z "$ZONE" ]; then
    handle_error "Zone cannot be empty. Exiting."
    exit 1
fi

progress "Setting compute region and zone..."
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

check_success "Region set to $REGION and Zone set to $ZONE" "Failed to set region/zone"

# Clone the repository
progress "Cloning GKE Tracing Demo repository..."
git clone https://github.com/GoogleCloudPlatform/gke-tracing-demo
check_success "Repository cloned" "Failed to clone repository"

cd gke-tracing-demo
check_success "Changed to gke-tracing-demo directory" "Failed to change directory"

# Terraform setup
progress "Setting up Terraform configuration..."
cd terraform

# Remove problematic Terraform version constraint
if [ -f "provider.tf" ]; then
    progress "Updating provider.tf configuration..."
    sed -i '/version = "~> 2.10.0"/d' provider.tf
    check_success "Provider configuration updated" "Failed to update provider.tf"
else
    handle_error "provider.tf not found"
    exit 1
fi

# Terraform initialization
progress "Initializing Terraform..."
terraform init
check_success "Terraform initialized" "Terraform init failed"

# Generate Terraform variables
progress "Generating Terraform variables..."
if [ -f "../scripts/generate-tfvars.sh" ]; then
    ../scripts/generate-tfvars.sh
    check_success "Terraform variables generated" "Failed to generate tfvars"
else
    handle_error "generate-tfvars.sh not found"
    exit 1
fi

# Terraform plan
progress "Creating Terraform execution plan..."
terraform plan
check_success "Terraform plan created" "Terraform plan failed"

# Terraform apply
progress "Applying Terraform configuration (this may take 10-15 minutes)..."
terraform apply -auto-approve
check_success "Terraform apply completed" "Terraform apply failed"

# Return to main directory
cd ..

# Deploy tracing demo
progress "Deploying tracing demo application..."
if [ -f "tracing-demo-deployment.yaml" ]; then
    kubectl apply -f tracing-demo-deployment.yaml
    check_success "Tracing demo deployed" "Failed to deploy tracing demo"
else
    handle_error "tracing-demo-deployment.yaml not found"
    exit 1
fi

# Wait for deployment to be ready
progress "Waiting for deployment to be ready..."
sleep 30
kubectl get pods -n default
kubectl get svc -n default

# Get the external IP
progress "Retrieving application endpoint..."
EXTERNAL_IP=$(kubectl get svc tracing-demo -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    APPLICATION_URL="http://${EXTERNAL_IP}?string=CustomMessage"
    echo ""
    echo "${GREEN}==================================================================${RESET}"
    echo "${BOLD}🎉 GKE TRACING DEMO DEPLOYMENT COMPLETED!${RESET}"
    echo "${GREEN}==================================================================${RESET}"
    echo ""
    echo "${BOLD}🌐 Application URL:${RESET}"
    echo "   ${BLUE}${APPLICATION_URL}${RESET}"
    echo ""
    echo "${BOLD}📊 To test the application:${RESET}"
    echo "   curl \"${APPLICATION_URL}\""
    echo ""
    echo "${BOLD}🔧 To view traces:${RESET}"
    echo "   Visit Google Cloud Console → Trace Explorer"
    echo ""
else
    echo "${YELLOW}⚠️  External IP not yet assigned. Checking status...${RESET}"
    kubectl describe svc tracing-demo -n default
    echo ""
    echo "${BOLD}The LoadBalancer may take a few minutes to provision.${RESET}"
    echo "${BOLD}Run this command later to get the URL:${RESET}"
    echo 'echo http://$(kubectl get svc tracing-demo -n default -o jsonpath='"'"'{.status.loadBalancer.ingress[0].ip}'"'"')?string=CustomMessage'
fi

# Display current resources
echo ""
echo "${GREEN}==================================================================${RESET}"
echo "${BOLD}📋 CURRENT DEPLOYMENT STATUS:${RESET}"
echo "${GREEN}==================================================================${RESET}"

progress "Listing pods:"
kubectl get pods -n default

progress "Listing services:"
kubectl get svc -n default

progress "Listing deployments:"
kubectl get deployments -n default

echo ""
echo "${BLUE}==================================================================${RESET}"
echo "${BOLD}📺 LIKE THIS TUTORIAL? SUBSCRIBE TO DR. ABHISHEK CLOUD TUTORIALS!${RESET}"
echo "${BLUE}🌐 YouTube: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo "${BLUE}==================================================================${RESET}"
echo "${BOLD}   Don't forget to LIKE, SHARE, and COMMENT on the tutorials!${RESET}"
echo "${BLUE}==================================================================${RESET}"

# Create a quick test script
cat > test_tracing_demo.sh << EOF
#!/bin/bash
echo "Testing GKE Tracing Demo Application..."
EXTERNAL_IP=\$(kubectl get svc tracing-demo -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "\$EXTERNAL_IP" ] && [ "\$EXTERNAL_IP" != "null" ]; then
    echo "Application URL: http://\${EXTERNAL_IP}?string=CustomMessage"
    echo "Testing with curl..."
    curl "http://\${EXTERNAL_IP}?string=CustomMessage"
else
    echo "External IP not yet assigned. Please wait and try again."
fi
EOF

chmod +x test_tracing_demo.sh

echo ""
echo "${GREEN}Quick test script created: ./test_tracing_demo.sh${RESET}"
