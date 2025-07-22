#!/bin/bash

# ==============================================
#  Google Cloud Load Balancer Setup 
#  Created by Dr. Abhishek Cloud Tutorials
#  YouTube: https://www.youtube.com/@drabhishek.5460
# ==============================================

# Text styles and colors
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Welcome Banner
echo
echo "${BLUE}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo "${BLUE}${BOLD}║   WELCOME TO DR. ABHISHEK CLOUD TUTORIALS ║${RESET}"
echo "${BLUE}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo
echo "${MAGENTA}Thank you for using our Google Cloud setup script!${RESET}"
echo "${YELLOW}Please like the video and subscribe to our channel:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
echo "${GREEN}Starting load balancer configuration...${RESET}"
echo

# Prompt user for region and zone
read -p "${YELLOW}Enter the region (e.g., us-central1): ${RESET}" REGION
read -p "${YELLOW}Enter the zone (e.g., us-central1-f): ${RESET}" ZONE

# Set the default region and zone
echo "${GREEN}Setting default region and zone...${RESET}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "${GREEN}✓ Region set to: $REGION${RESET}"
echo "${GREEN}✓ Zone set to: $ZONE${RESET}"
echo

# Task 2. Create multiple web server instances
echo "${BLUE}${BOLD}Creating web server instances...${RESET}"

create_vm() {
  local vm_name=$1
  local zone=$2
  
  echo "${YELLOW}Creating instance: $vm_name in zone: $zone${RESET}"
  gcloud compute instances create $vm_name \
    --zone=$zone \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: '$vm_name'</h3>" | tee /var/www/html/index.html'
  
  echo "${GREEN}✓ Instance $vm_name created successfully${RESET}"
}

create_vm web1 $ZONE
create_vm web2 $ZONE
create_vm web3 $ZONE

# Create firewall rule
echo "${BLUE}${BOLD}Creating firewall rule...${RESET}"
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80
echo "${GREEN}✓ Firewall rule created${RESET}"

# Verify instances
echo "${BLUE}${BOLD}Listing instances...${RESET}"
gcloud compute instances list

# Task 2. Configure the load balancing service
echo "${BLUE}${BOLD}Configuring network load balancing service...${RESET}"

# Create static IP address with specified name
gcloud compute addresses create network-lb-ip-1 \
  --region $REGION

# Create target pool with specified name
gcloud compute target-pools create www-pool \
  --region $REGION

# Add instances to target pool
gcloud compute target-pools add-instances www-pool \
  --instances web1,web2,web3 \
  --instances-zone $ZONE

# Create forwarding rule with specified values
gcloud compute forwarding-rules create www-rule \
  --region $REGION \
  --ports 80 \
  --address network-lb-ip-1 \
  --target-pool www-pool

# Get the load balancer IP
LB_IP=$(gcloud compute addresses describe network-lb-ip-1 \
  --region $REGION \
  --format='value(address)')
echo "${GREEN}✓ Network Load Balancer IP: $LB_IP${RESET}"

# Task 3. Create an Application Load Balancer
echo "${BLUE}${BOLD}Creating application load balancer components...${RESET}"

# Create load balancer template
gcloud compute instance-templates create lb-backend-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'

# Create managed instance group
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=$ZONE

# Create health check firewall rule
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Create static IP address for application LB
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

# Get the reserved IP address
APP_LB_IP=$(gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global)
echo "${GREEN}✓ Application Load Balancer IP: $APP_LB_IP${RESET}"

# Create health check
gcloud compute health-checks create http http-basic-check \
  --port 80

# Create backend service
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# Add backend to the service
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

# Create URL map
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

# Create target HTTP proxy
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

# Create forwarding rule
gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1 \
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80

# Final output
echo
echo "${BLUE}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo "${BLUE}${BOLD}║        SETUP COMPLETED SUCCESSFULLY      ║${RESET}"
echo "${BLUE}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo
echo "${GREEN}Network Load Balancer IP: http://$LB_IP${RESET}"
echo "${GREEN}Application Load Balancer IP: http://$APP_LB_IP${RESET}"
echo
echo "${YELLOW}Thank you !${RESET}"
echo "${MAGENTA}Please like and subscribe for more cloud tutorials:${RESET}"
echo "${BLUE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
