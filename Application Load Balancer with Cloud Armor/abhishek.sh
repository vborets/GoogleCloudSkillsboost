#!/bin/bash

DARK_BLUE=$(tput setaf 27)
TEAL=$(tput setaf 50)
PURPLE=$(tput setaf 129)
ORANGE=$(tput setaf 208)
LIME=$(tput setaf 118)
PINK=$(tput setaf 200)
RED=$(tput setaf 196)
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

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

# Function to validate input
validate_input() {
    local input=$1
    local name=$2
    if [[ -z "$input" ]]; then
        echo "${RED}${BOLD}Error: $name cannot be empty${RESET}"
        exit 1
    fi
}

# Clear screen and display header
clear
echo
echo "${DARK_BLUE}${BOLD}╔════════════════════════════════════════════════════╗"
echo "           WELCOME TO DR ABHISHEK CLOUD TUTORIALS          "
echo "╚════════════════════════════════════════════════════╝${RESET}"
echo

# Collect user input with validation
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 1: CONFIGURATION ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
read -p "${YELLOW}${BOLD}Enter the first region (e.g. us-central1): ${RESET}" REGION1
validate_input "$REGION1" "Region1"

read -p "${YELLOW}${BOLD}Enter the second region (e.g. europe-west1): ${RESET}" REGION2
validate_input "$REGION2" "Region2"

read -p "${YELLOW}${BOLD}Enter the VM zone (e.g. us-central1-c): ${RESET}" VM_ZONE
validate_input "$VM_ZONE" "VM Zone"

export REGION1 REGION2 VM_ZONE
export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

echo
echo "${LIME}${BOLD}✔ Configuration set:"
echo "  Region 1: ${TEAL}$REGION1"
echo "  Region 2: ${TEAL}$REGION2"
echo "  VM Zone: ${TEAL}$VM_ZONE"
echo "  Project: ${TEAL}$DEVSHELL_PROJECT_ID${RESET}"
echo

# Step 2: Firewall Rules
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 2: FIREWALL RULES ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo -n "${TEAL}${BOLD}🛡️ Creating HTTP firewall rule..."
(gcloud compute firewall-rules create default-allow-http \
    --project=$DEVSHELL_PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --action=ALLOW \
    --rules=tcp:80 > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ HTTP firewall rule created!          ${RESET}"

echo -n "${TEAL}${BOLD}🛡️ Creating health check firewall rule..."
(gcloud compute firewall-rules create default-allow-health-check \
    --project=$DEVSHELL_PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=http-server \
    --action=ALLOW \
    --rules=tcp > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Health check firewall rule created!          ${RESET}"
echo

# Step 3: Instance Templates
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 3: INSTANCE TEMPLATES ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo -n "${TEAL}${BOLD}🖥️ Creating $REGION1 instance template..."
(gcloud compute instance-templates create $REGION1-template \
    --project=$DEVSHELL_PROJECT_ID \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --region=$REGION1 \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=$REGION1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ $REGION1 instance template created!          ${RESET}"

echo -n "${TEAL}${BOLD}🖥️ Creating $REGION2 instance template..."
(gcloud compute instance-templates create $REGION2-template \
    --project=$DEVSHELL_PROJECT_ID \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --region=$REGION2 \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=$REGION2-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ $REGION2 instance template created!          ${RESET}"
echo

# Step 4: Managed Instance Groups
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 4: MANAGED INSTANCE GROUPS ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo -n "${TEAL}${BOLD}🔄 Creating $REGION1 managed instance group..."
(gcloud beta compute instance-groups managed create $REGION1-mig \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=$REGION1-mig \
    --size=1 \
    --template=$REGION1-template \
    --region=$REGION1 \
    --target-distribution-shape=EVEN \
    --instance-redistribution-type=PROACTIVE \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ $REGION1 managed instance group created!          ${RESET}"

echo -n "${TEAL}${BOLD}📈 Setting autoscaling for $REGION1 group..."
(gcloud beta compute instance-groups managed set-autoscaling $REGION1-mig \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION1 \
    --cool-down-period=45 \
    --max-num-replicas=2 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8 > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Autoscaling configured for $REGION1 group!          ${RESET}"

echo -n "${TEAL}${BOLD}🔄 Creating $REGION2 managed instance group..."
(gcloud beta compute instance-groups managed create $REGION2-mig \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=$REGION2-mig \
    --size=1 \
    --template=$REGION2-template \
    --region=$REGION2 \
    --target-distribution-shape=EVEN \
    --instance-redistribution-type=PROACTIVE \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ $REGION2 managed instance group created!          ${RESET}"

echo -n "${TEAL}${BOLD}📈 Setting autoscaling for $REGION2 group..."
(gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION2 \
    --cool-down-period=45 \
    --max-num-replicas=2 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8 > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Autoscaling configured for $REGION2 group!          ${RESET}"
echo

# Step 5: Load Balancer Components
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 5: LOAD BALANCER SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
TOKEN=$(gcloud auth application-default print-access-token)

echo -n "${TEAL}${BOLD}🩺 Creating health check..."
(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "http-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/healthChecks" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Health check created!          ${RESET}"

sleep 10  # Allow health check to propagate

echo -n "${TEAL}${BOLD}⚖️ Creating backend service..."
(curl -s -X POST -H "Content-Type: application/json" \
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
      "maxTtl": 86400,
      "negativeCaching": false,
      "serveWhileStale": 0
    },
    "compressionMode": "DISABLED",
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "enableCDN": true,
    "healthChecks": [
      "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"
    ],
    "loadBalancingScheme": "EXTERNAL",
    "logConfig": {
      "enable": true,
      "sampleRate": 1
    },
    "name": "http-backend"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Backend service created!          ${RESET}"

sleep 20  # Allow backend service to propagate

echo -n "${TEAL}${BOLD}🗺️ Creating URL map..."
(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
    "name": "http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ URL map created!          ${RESET}"

sleep 15  # Allow URL map to propagate

echo -n "${TEAL}${BOLD}🎯 Creating target HTTP proxy..."
(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Target HTTP proxy created!          ${RESET}"

sleep 15  # Allow target proxy to propagate

echo -n "${TEAL}${BOLD}🚦 Creating IPv4 forwarding rule..."
(curl -s -X POST -H "Content-Type: application/json" \
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
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ IPv4 forwarding rule created!          ${RESET}"

sleep 15  # Allow forwarding rule to propagate

echo -n "${TEAL}${BOLD}🎯 Creating second target HTTP proxy..."
(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "http-lb-target-proxy-2",
    "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Second target HTTP proxy created!          ${RESET}"

sleep 15  # Allow target proxy to propagate

echo -n "${TEAL}${BOLD}🚦 Creating IPv6 forwarding rule..."
(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV6",
    "loadBalancingScheme": "EXTERNAL",
    "name": "http-lb-forwarding-rule-2",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy-2"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ IPv6 forwarding rule created!          ${RESET}"

sleep 15  # Allow forwarding rule to propagate

# Step 6: Siege VM Setup
echo "${PURPLE}${BOLD}▐▓▒▌ STEP 6: TESTING SETUP ${DARK_BLUE}${BOLD}◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈◈${RESET}"
echo
echo -n "${TEAL}${BOLD}🖥️ Creating Siege VM..."
(gcloud compute instances create siege-vm \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$VM_ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$VM_ZONE/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Siege VM created!          ${RESET}"

sleep 30  # Allow VM to boot

echo -n "${TEAL}${BOLD}📡 Getting Siege VM external IP..."
export EXTERNAL_IP=$(gcloud compute instances describe siege-vm --zone=$VM_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
echo -e "\r${LIME}${BOLD}✔ Siege VM IP: ${TEAL}$EXTERNAL_IP          ${RESET}"

echo -n "${TEAL}${BOLD}🛡️ Creating security policy..."
(curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
  -d '{
    "adaptiveProtectionConfig": {
      "layer7DdosDefenseConfig": {
        "enable": false
      }
    },
    "description": "",
    "name": "denylist-siege",
    "rules": [
      {
        "action": "deny(403)",
        "description": "",
        "match": {
          "config": {
            "srcIpRanges": [
               "'"${EXTERNAL_IP}"'"
            ]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "preview": false,
        "priority": 1000
      },
      {
        "action": "allow",
        "description": "Default rule, higher priority overrides it",
        "match": {
          "config": {
            "srcIpRanges": [
              "*"
            ]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "preview": false,
        "priority": 2147483647
      }
    ],
    "type": "CLOUD_ARMOR"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Security policy created!          ${RESET}"

sleep 15  # Allow policy to propagate

echo -n "${TEAL}${BOLD}🔗 Applying security policy to backend..."
(curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
  -d "{
    \"securityPolicy\": \"projects/$DEVSHELL_PROJECT_ID/global/securityPolicies/denylist-siege\"
  }" \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy" > /dev/null 2>&1) &
spinner
echo -e "\r${LIME}${BOLD}✔ Security policy applied!          ${RESET}"

# Get Load Balancer IP
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)")

# Completion Message
echo
echo "${DARK_BLUE}${BOLD}╔════════════════════════════════════════════════════╗"
echo "           GLOBAL HTTP LOAD BALANCER SETUP COMPLETE!      "
echo "╚════════════════════════════════════════════════════╝${RESET}"
echo
echo "${LIME}${BOLD}✔ Load Balancer IP: ${TEAL}$LB_IP_ADDRESS${RESET}"
echo "${LIME}${BOLD}✔ Siege VM IP: ${TEAL}$EXTERNAL_IP${RESET}"
echo
echo "${YELLOW}${BOLD}To run the load test:"
echo "1. SSH into the Siege VM:"
echo "   ${TEAL}gcloud compute ssh --zone $VM_ZONE siege-vm${RESET}"
echo "2. Install Siege and run the test:"
echo "   ${TEAL}sudo apt-get install -y siege && siege -c 150 -t 120s http://$LB_IP_ADDRESS${RESET}"
echo
echo "${PURPLE}${BOLD}For more cloud engineering tutorials, visit:"
echo "${TEAL}https://www.youtube.com/@drabhishek.5460/${RESET}"
echo
