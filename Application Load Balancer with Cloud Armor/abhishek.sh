#!/bin/bash
# Color definitions
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_PURPLE='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Clear screen and display welcome banner
clear
echo -e "${BRIGHT_CYAN}${BOLD}"
echo "  ____                          _     _ _     _       "
echo " |  _ \ _ __ ___   ___ ___   __| | __| | |__ | | ___ "
echo " | | | | '__/ _ \ / __/ _ \ / _\` |/ _\` | '_ \| |/ _ \\"
echo " | |_| | | | (_) | (_| (_) | (_| | (_| | |_) | |  __/"
echo " |____/|_|  \___/ \___\___/ \__,_|\__,_|_.__/|_|\___|"
echo -e "${RESET}"
echo -e "${BRIGHT_WHITE}${BOLD}Welcome to Dr. Abhishek's Cloud Tutorials${RESET}"
echo -e "${BRIGHT_WHITE}YouTube: ${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}=========================================${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}         WELCOME TO DR ABHISHEK CLOUD TUTORIAL          ${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}=========================================${RESET}"
echo

# Collect user input
read -p "${BRIGHT_YELLOW}${BOLD}Enter the first REGION: ${RESET}" REGION1
echo -e "${BRIGHT_GREEN}${BOLD}First REGION set to:${RESET} ${BRIGHT_CYAN}${BOLD}$REGION1${RESET}"
echo

read -p "${BRIGHT_YELLOW}${BOLD}Enter the second REGION: ${RESET}" REGION2
echo -e "${BRIGHT_GREEN}${BOLD}Second REGION set to:${RESET} ${BRIGHT_CYAN}${BOLD}$REGION2${RESET}"
echo

read -p "${BRIGHT_YELLOW}${BOLD}Enter the VM_ZONE: ${RESET}" VM_ZONE
echo -e "${BRIGHT_GREEN}${BOLD}VM_ZONE set to:${RESET} ${BRIGHT_CYAN}${BOLD}$VM_ZONE${RESET}"
echo

# Export variables
export REGION1 REGION2 VM_ZONE
export INSTANCE_NAME=$REGION1-mig
export INSTANCE_NAME_2=$REGION2-mig

# Function to display status messages
status() {
    echo -e "${BRIGHT_BLUE}${BOLD}[$(date +'%T')] ${1}${RESET}"
}

# Function to handle errors
error() {
    echo -e "${BRIGHT_RED}${BOLD}[ERROR] ${1}${RESET}"
    exit 1
}

# Configure firewall rules
status "Configuring firewall rules..."
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-http \
    --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
    --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server || error "Failed to create HTTP firewall rule"

gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create default-allow-health-check \
    --direction=INGRESS --priority=1000 --network=default --action=ALLOW \
    --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server || error "Failed to create health check firewall rule"

# Create instance templates
status "Creating instance templates..."
gcloud compute instance-templates create $REGION1-template \
    --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION1 \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any || error "Failed to create $REGION1 template"

gcloud compute instance-templates create $REGION2-template \
    --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=$REGION2 \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any || error "Failed to create $REGION2 template"

# Create managed instance groups
status "Creating managed instance groups..."
gcloud beta compute instance-groups managed create $REGION1-mig \
    --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION1-mig \
    --size=1 --template=$REGION1-template --region=$REGION1 \
    --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE \
    --list-managed-instances-results=PAGELESS --no-force-update-on-repair || error "Failed to create $REGION1 MIG"

gcloud beta compute instance-groups managed set-autoscaling $REGION1-mig \
    --project=$DEVSHELL_PROJECT_ID --region=$REGION1 \
    --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 \
    --mode=on --target-cpu-utilization=0.8 || error "Failed to set autoscaling for $REGION1 MIG"

gcloud beta compute instance-groups managed create $REGION2-mig \
    --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION2-mig \
    --size=1 --template=$REGION2-template --region=$REGION2 \
    --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE \
    --list-managed-instances-results=PAGELESS --no-force-update-on-repair || error "Failed to create $REGION2 MIG"

gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig \
    --project=$DEVSHELL_PROJECT_ID --region=$REGION2 \
    --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 \
    --mode=on --target-cpu-utilization=0.8 || error "Failed to set autoscaling for $REGION2 MIG"

# Load balancer setup
DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

status "Creating health check..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "checkIntervalSec": 5,
        "healthyThreshold": 2,
        "name": "http-health-check",
        "tcpHealthCheck": {"port": 80, "proxyHeader": "NONE"},
        "timeoutSec": 5,
        "type": "TCP",
        "unhealthyThreshold": 2
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/healthChecks" || error "Failed to create health check"
sleep 60

status "Creating backend service..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "backends": [
            {
                "balancingMode": "RATE",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION1"'/instanceGroups/'"$REGION1-mig"'",
                "maxRatePerInstance": 50
            },
            {
                "balancingMode": "UTILIZATION",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION2"'/instanceGroups/'"$REGION2-mig"'",
                "maxRatePerInstance": 80,
                "maxUtilization": 0.8
            }
        ],
        "cdnPolicy": {
            "cacheKeyPolicy": {
                "includeHost": true,
                "includeProtocol": true,
                "includeQueryString": true
            },
            "cacheMode": "CACHE_ALL_STATIC",
            "clientTtl": 3600,
            "defaultTtl": 3600,
            "maxTtl": 86400
        },
        "enableCDN": true,
        "healthChecks": ["projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"],
        "loadBalancingScheme": "EXTERNAL",
        "logConfig": {"enable": true, "sampleRate": 1},
        "name": "http-backend"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices" || error "Failed to create backend service"
sleep 60

status "Creating URL map..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
        "name": "http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps" || error "Failed to create URL map"
sleep 60

status "Creating target HTTP proxy..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "http-lb-target-proxy",
        "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies" || error "Failed to create target HTTP proxy"
sleep 60

status "Creating forwarding rule..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "IPProtocol": "TCP",
        "ipVersion": "IPV4",
        "loadBalancingScheme": "EXTERNAL",
        "name": "http-lb-forwarding-rule",
        "networkTier": "PREMIUM",
        "portRange": "80",
        "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules" || error "Failed to create forwarding rule"
sleep 60

status "Setting named ports for instance groups..."
curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"namedPorts": [{"name": "http", "port": 80}]}' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION2/instanceGroups/$INSTANCE_NAME_2/setNamedPorts" || error "Failed to set named ports for $REGION2"
sleep 60

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"namedPorts": [{"name": "http", "port": 80}]}' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION1/instanceGroups/$INSTANCE_NAME/setNamedPorts" || error "Failed to set named ports for $REGION1"
sleep 60

status "Creating siege VM for testing..."
gcloud compute instances create siege-vm \
    --project=$DEVSHELL_PROJECT_ID --zone=$VM_ZONE \
    --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD \
    --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/us-central1-c/diskTypes/pd-balanced \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any || error "Failed to create siege VM"
sleep 60

status "Retrieving siege VM external IP..."
export EXTERNAL_IP=$(gcloud compute instances describe siege-vm --zone=$VM_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)") || error "Failed to get siege VM IP"
echo -e "${BRIGHT_GREEN}Siege VM External IP: ${BRIGHT_CYAN}$EXTERNAL_IP${RESET}"
sleep 20

status "Creating Cloud Armor security policy..."
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d '{
        "name": "denylist-siege",
        "rules": [
            {
                "action": "deny(403)",
                "match": {
                    "config": {"srcIpRanges": ["'"${EXTERNAL_IP}"'"]},
                    "versionedExpr": "SRC_IPS_V1"
                },
                "priority": 1000
            },
            {
                "action": "allow",
                "match": {
                    "config": {"srcIpRanges": ["*"]},
                    "versionedExpr": "SRC_IPS_V1"
                },
                "priority": 2147483647
            }
        ],
        "type": "CLOUD_ARMOR"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies" || error "Failed to create security policy"
sleep 60

status "Attaching security policy to backend service..."
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d "{\"securityPolicy\": \"projects/$DEVSHELL_PROJECT_ID/global/securityPolicies/denylist-siege\"}" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy" || error "Failed to attach security policy"
sleep 60

status "Retrieving load balancer IP address..."
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)") || error "Failed to get LB IP"
echo -e "${BRIGHT_GREEN}Load Balancer IP Address: ${BRIGHT_CYAN}$LB_IP_ADDRESS${RESET}"

status "Running siege test from the siege VM..."
gcloud compute ssh --zone "$VM_ZONE" "siege-vm" --project "$DEVSHELL_PROJECT_ID" --quiet \
    --command "sudo apt-get -y update && sudo apt-get -y install siege && export LB_IP=$LB_IP_ADDRESS && echo 'Starting siege test...' && siege -c 150 -t 120s http://\$LB_IP && echo 'Siege test finished.'" || error "Siege test failed"

echo -e "${BRIGHT_GREEN}${BOLD}"
echo "========================================="
echo "          DEPLOYMENT COMPLETE            "
echo "========================================="
echo -e "${RESET}"
echo -e "${BRIGHT_WHITE}Thank you${RESET}"
echo -e "${BRIGHT_WHITE}For more tutorials, visit: ${UNDERLINE}https://www.youtube.com/@drabhishek.5460${RESET}"
echo
