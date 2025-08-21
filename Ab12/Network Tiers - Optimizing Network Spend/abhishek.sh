
#!/bin/bash

# ==============================================
# Google Cloud VM Creation with Network Tiers
# Welcome to Dr. Abhishek Cloud Tutorials!
# YouTube: https://www.youtube.com/@drabhishek.5460/videos
# ==============================================

# Color definitions
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display enhanced banner
display_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🚀 CLOUD MASTERY SERIES 🚀                 ║"
    echo "║                                                              ║"
    echo "║           📺 DR. ABHISHEK CLOUD TUTORIALS 📺                ║"
    echo "║                                                              ║"
    echo "║    🌐 YouTube: https://www.youtube.com/@drabhishek.5460     ║"
    echo "║    ⭐ Subscribe for Daily Cloud & DevOps Content ⭐         ║"
    echo "║                                                              ║"
    echo "║         💻 Google Cloud VM Network Tiers Demo 💻           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${MAGENTA}${BOLD}🎯 Learn: Premium vs Standard Network Tiers${NC}"
    echo -e "${MAGENTA}${BOLD}🎯 Build: Hands-on Google Cloud Infrastructure${NC}"
    echo -e "${MAGENTA}${BOLD}🎯 Master: Real-world Cloud Networking Concepts${NC}"
    echo ""
}

# Function to display progress
progress() {
    echo -e "${GREEN}✅${NC} ${BOLD}$1${NC}"
    sleep 1
}

# Function to handle errors
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    sleep 2
}

# Display initial banner
display_banner

# Get zone input from user
echo -e "${BOLD}Please enter your preferred zone:${NC}"
echo -e "${BLUE}Common zones: us-central1-a, us-east1-b, europe-west1-c, asia-southeast1-a${NC}"
read -p "Enter the ZONE (press Enter for default): " ZONE_INPUT

# Set zone - use input or default
if [ -z "$ZONE_INPUT" ]; then
    # Get default zone if no input provided
    ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
    if [ -z "$ZONE" ]; then
        handle_error "Could not determine default zone. Please specify a zone manually."
        echo "Available zones:"
        gcloud compute zones list --format="value(name)" | head -10
        exit 1
    fi
    echo -e "${GREEN}Using default zone: ${BOLD}$ZONE${NC}"
else
    ZONE="$ZONE_INPUT"
    echo -e "${GREEN}Using specified zone: ${BOLD}$ZONE${NC}"
fi

# Validate the zone
progress "Validating zone..."
if ! gcloud compute zones list --format="value(name)" | grep -q "^$ZONE$"; then
    handle_error "Invalid zone: $ZONE"
    echo "Available zones in your project:"
    gcloud compute zones list --format="value(name)" | head -10
    exit 1
fi

# Export region from zone
export ZONE="$ZONE"
export REGION="${ZONE%-*}"

progress "Setting compute configuration..."
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo -e "${BOLD}Configuration:${NC}"
echo -e "  Zone: ${BLUE}$ZONE${NC}"
echo -e "  Region: ${BLUE}$REGION${NC}"
echo ""

# Create Premium tier VM
progress "Creating Premium network tier VM..."
gcloud compute instances create vm-premium \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --tags=http-server,https-server

check_success "Premium VM created" "Failed to create Premium VM"

# Create Standard tier VM
progress "Creating Standard network tier VM..."
gcloud compute instances create vm-standard \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=STANDARD \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --tags=http-server,https-server

check_success "Standard VM created" "Failed to create Standard VM"

# Display created VMs
progress "Listing created instances..."
echo -e "${BOLD}Created Virtual Machines:${NC}"
gcloud compute instances list --filter="zone:($ZONE)" --format="table(name, zone, machineType, networkInterfaces[0].accessConfigs[0].networkTier, status)"

# Display network tier information
echo ""
echo -e "${BOLD}📊 Network Tier Comparison:${NC}"
echo -e "${GREEN}PREMIUM Tier${NC}:"
echo "  - Global load balancing"
echo "  - Lower latency"
echo "  - Higher performance"
echo "  - Recommended for production workloads"
echo ""
echo -e "${YELLOW}STANDARD Tier${NC}:"
echo "  - Regional load balancing"
echo "  - Cost-effective"
echo "  - Suitable for dev/test environments"
echo ""

# Display connection information
echo -e "${BOLD}🔗 SSH Connection Commands:${NC}"
echo -e "Connect to Premium VM:  ${BLUE}gcloud compute ssh vm-premium --zone=$ZONE${NC}"
echo -e "Connect to Standard VM: ${BLUE}gcloud compute ssh vm-standard --zone=$ZONE${NC}"
echo ""

# Display completion banner
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   🎉 MISSION ACCOMPLISHED! 🎉               ║"
echo "║                                                              ║"
echo "║          ✅ Successfully Created 2 Google Cloud VMs         ║"
echo "║          ✅ Configured Different Network Tiers             ║"
echo "║          ✅ Hands-on Learning Complete                     ║"
echo "║                                                              ║"
echo "║    📺 Don't forget to like and subscribe on YouTube!       ║"
echo "║    🌐 https://www.youtube.com/@drabhishek.5460             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Final summary
echo -e "${GREEN}${BOLD}**********************************************************${NC}"
echo -e "${GREEN}${BOLD}**               VM CREATION COMPLETED!                 **${NC}"
echo -e "${GREEN}${BOLD}**                                                      **${NC}"
echo -e "${GREEN}${BOLD}**    Successfully created 2 VMs with different         **${NC}"
echo -e "${GREEN}${BOLD}**    network tiers in zone: ${ZONE}                    **${NC}"
echo -e "${GREEN}${BOLD}**********************************************************${NC}"

# Create verification script
cat > verify_vms.sh << EOF
#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║               🔍 VERIFYING VM DEPLOYMENT 🔍                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Checking VMs in zone: $ZONE"
echo ""
echo "1. Listing all VMs:"
gcloud compute instances list --filter="zone:($ZONE)" --format="table(name, zone, machineType, networkInterfaces[0].accessConfigs[0].networkTier, status)"
echo ""
echo "2. Network tier details:"
gcloud compute instances describe vm-premium --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].networkTier)" | xargs -I {} echo "🟢 vm-premium Network Tier: {}"
gcloud compute instances describe vm-standard --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].networkTier)" | xargs -I {} echo "🟡 vm-standard Network Tier: {}"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   ✅ VERIFICATION COMPLETE ✅               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
EOF

chmod +x verify_vms.sh

echo ""
echo -e "${GREEN}Verification script created: ./verify_vms.sh${NC}"
echo -e "${GREEN}Run it to check your VM details.${NC}"

# Export variables for future use
echo ""
echo -e "${BOLD}Exported variables:${NC}"
echo "export ZONE=\"$ZONE\""
echo "export REGION=\"$REGION\""

# Final call to action
echo ""
echo -e "${MAGENTA}${BOLD}💡 Next Video Suggestion:${NC}"
echo -e "${BLUE}• Load Balancer Configuration with Different Network Tiers${NC}"
echo -e "${BLUE}• Cost Comparison: Premium vs Standard Tier Pricing${NC}"
echo -e "${BLUE}• Performance Testing Between Network Tiers${NC}"
echo ""
echo -e "${YELLOW}${BOLD}👍 Like this script? Subscribe for more cloud tutorials!${NC}"
