#!/bin/bash


# Modern Color Definitions
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Box Drawing Characters
BOX_TOP="${BLUE}╔════════════════════════════════════════════╗${NC}"
BOX_MID="${BLUE}║                                            ║${NC}"
BOX_BOT="${BLUE}╚════════════════════════════════════════════╝${NC}"

# Header with branding
clear
echo -e "${BOX_TOP}"
echo -e "${BLUE}║   🚀 GKE Logging Sinks Deployment Setup   ║${NC}"
echo -e "${BOX_BOT}"
echo -e "${CYAN}📺 YouTube: ${WHITE}https://youtube.com/@drabhishek.5460${NC}"
echo -e "${CYAN}⭐ Subscribe for more GKE tutorials! ⭐${NC}"
echo

# Function to set and export zone
set_zone() {
    echo -e "${YELLOW}🌍 Configuring Zone Settings${NC}"
    
    # Try to get default zone
    export ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
    
    if [ -z "$ZONE" ]; then
        echo -e "${YELLOW}No default zone configured.${NC}"
        echo -e "${CYAN}Available zones in your project:${NC}"
        gcloud compute zones list --format="value(name)" | sort | pr -3 -t
        
        while true; do
            read -p "${WHITE}Enter your preferred zone (e.g. us-central1-a): ${NC}" ZONE
            if gcloud compute zones describe $ZONE &>/dev/null; then
                break
            else
                echo -e "${RED}Invalid zone. Please try again.${NC}"
            fi
        done
        
        # Set zone in gcloud config
        gcloud config set compute/zone $ZONE
    fi
    
    echo -e "${GREEN}✅ Using zone: ${WHITE}$ZONE${NC}"
    export ZONE
    export REGION="${ZONE%-*}"
    echo -e "${GREEN}✅ Derived region: ${WHITE}$REGION${NC}"
}

# Main execution
set_zone

# Set project configuration
echo -e "\n${YELLOW}⚙️ Configuring Project Settings${NC}"
export PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $DEVSHELL_PROJECT_ID
echo -e "${GREEN}✅ Project set to: ${WHITE}$DEVSHELL_PROJECT_ID${NC}"

# Clone repository
echo -e "\n${YELLOW}📥 Cloning GKE Logging Sinks Demo Repository${NC}"
git clone https://github.com/GoogleCloudPlatform/gke-logging-sinks-demo
sleep 10

cd gke-logging-sinks-demo || {
    echo -e "${RED}❌ Failed to change directory${NC}"
    exit 1
}
sleep 10

# Configure region and zone
echo -e "\n${YELLOW}🌐 Setting Compute Region/Zone${NC}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo -e "${GREEN}✅ Region: ${WHITE}$REGION${NC}"
echo -e "${GREEN}✅ Zone: ${WHITE}$ZONE${NC}"

# Update Terraform configuration
echo -e "\n${YELLOW}🔄 Updating Terraform Configuration${NC}"
sed -i 's/  version = "~> 2.11.0"/  version = "~> 2.19.0"/g' terraform/provider.tf
sed -i 's/  filter      = "resource.type = container"/  filter      = "resource.type = k8s_container"/g' terraform/main.tf
echo -e "${GREEN}✅ Configuration updated${NC}"

# Execute Terraform
echo -e "\n${YELLOW}🚀 Deploying Infrastructure${NC}"
make create
make validate

# Logging queries
echo -e "\n${YELLOW}🔍 Querying GKE Logs${NC}"
echo -e "${CYAN}Running initial log query...${NC}"
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$PROJECT_ID

echo -e "\n${CYAN}Running detailed JSON log query...${NC}"
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$PROJECT_ID --format=json

# Create logging sink
echo -e "\n${YELLOW}📊 Creating BigQuery Logging Sink${NC}"
gcloud logging sinks create gke_logs_sink \
    bigquery.googleapis.com/projects/$PROJECT_ID/datasets/bq_logs \
    --log-filter='resource.type="k8s_container" 
resource.labels.cluster_name="stackdriver-logging"' \
    --include-children \
    --format='json'

sleep 17

# BigQuery query
echo -e "\n${YELLOW}📈 Querying BigQuery Logs${NC}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`$DEVSHELL_PROJECT_ID.gke_logs_dataset.diagnostic_log_*\`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', CURRENT_DATE() - INTERVAL 1 DAY) AND FORMAT_DATE('%Y%m%d', CURRENT_DATE()) 
"

# Completion message
echo -e "\n${GREEN}${BOLD}╔════════════════════════════════════════════╗"
echo -e "║          🎉 Deployment Completed! 🎉          ║"
echo -e "╚════════════════════════════════════════════╝${NC}"
echo -e "${WHITE}Thank you for using Dr. Abhishek's Cloud Lab!${NC}"
echo -e "${CYAN}For more tutorials: ${WHITE}https://youtube.com/@drabhishek.5460${NC}"
