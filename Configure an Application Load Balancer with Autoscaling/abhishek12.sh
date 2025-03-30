#!/bin/bash

# Enable error reporting and logging
set -e
exec > >(tee -i dynamic_lab_setup.log)
exec 2>&1

echo "Starting automated lab setup with dynamic zone selection..."

# Get project details
PROJECT_ID=$(gcloud config get-value project)
DEFAULT_REGION=$(gcloud compute project-info describe --format="value(defaultComputeRegion)")

# Function to get random zone from a region
get_random_zone() {
    local region=$1
    gcloud compute zones list --filter="region=$region" --format="value(name)" | shuf -n 1
}

# Dynamically select two distinct regions
REGIONS=($(gcloud compute regions list --format="value(name)" | shuf -n 2))
REGION1=${REGIONS[0]}
REGION2=${REGIONS[1]}
ZONE1=$(get_random_zone $REGION1)
ZONE2=$(get_random_zone $REGION2)

echo "Selected regions: $REGION1 (zone: $ZONE1) and $REGION2 (zone: $ZONE2)"

# Task 1: Configure Health Check Firewall Rule
echo "Creating health check firewall rule..."
gcloud compute firewall-rules create fw-allow-health-checks \
    --network=default \
    --action=allow \
    --direction=INGRESS \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-health-checks

# Task 2: Create NAT Configuration in first region
echo "Setting up Cloud NAT in $REGION1..."
gcloud compute routers create nat-router-dynamic \
    --region=${REGION1} \
    --network=default

gcloud compute routers nats create nat-config-dynamic \
    --router=nat-router-dynamic \
    --router-region=${REGION1} \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges

# Task 3: Create Custom Web Server Image
echo "Creating web server VM in $ZONE1..."
gcloud compute instances create webserver-dynamic \
    --zone=${ZONE1} \
    --machine-type=e2-micro \
    --tags=allow-health-checks \
    --no-address \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --metadata=startup-script='#! /bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo service apache2 start
    sudo update-rc.d apache2 enable'

echo "Waiting 2 minutes for VM to initialize..."
sleep 120

echo "Creating custom image..."
gcloud compute images create mywebserver-dynamic \
    --source-disk=webserver-dynamic \
    --source-disk-zone=${ZONE1}

echo "Cleaning up web server VM..."
gcloud compute instances delete webserver-dynamic \
    --zone=${ZONE1} \
    --keep-disks=boot \
    --quiet

# Task 4: Configure Instance Template and Groups
echo "Creating instance template..."
gcloud compute instance-templates create mywebserver-template-dynamic \
    --machine-type=e2-micro \
    --tags=allow-health-checks \
    --no-address \
    --image=mywebserver-dynamic \
    --network=default

echo "Creating health check..."
gcloud compute health-checks create tcp http-health-check-dynamic \
    --port=80

# Create managed instance groups in both regions
echo "Creating MIG in $REGION1 ($ZONE1)..."
gcloud compute instance-groups managed create mig-dynamic-1 \
    --template=mywebserver-template-dynamic \
    --size=1 \
    --zone=${ZONE1} \
    --health-check=http-health-check-dynamic \
    --initial-delay=60

echo "Creating MIG in $REGION2 ($ZONE2)..."
gcloud compute instance-groups managed create mig-dynamic-2 \
    --template=mywebserver-template-dynamic \
    --size=1 \
    --zone=${ZONE2} \
    --health-check=http-health-check-dynamic \
    --initial-delay=60

# Configure autoscaling
echo "Configuring autoscaling..."
gcloud compute instance-groups managed set-autoscaling mig-dynamic-1 \
    --zone=${ZONE1} \
    --max-num-replicas=2 \
    --target-load-balancing-utilization=0.8 \
    --cool-down-period=60

gcloud compute instance-groups managed set-autoscaling mig-dynamic-2 \
    --zone=${ZONE2} \
    --max-num-replicas=2 \
    --target-load-balancing-utilization=0.8 \
    --cool-down-period=60

# Task 5: Configure HTTP Load Balancer
echo "Creating load balancer..."
gcloud compute backend-services create http-backend-dynamic \
    --protocol=HTTP \
    --health-checks=http-health-check-dynamic \
    --global

# Add backends
gcloud compute backend-services add-backend http-backend-dynamic \
    --instance-group=mig-dynamic-1 \
    --instance-group-zone=${ZONE1} \
    --balancing-mode=RATE \
    --max-rate-per-instance=50 \
    --global

gcloud compute backend-services add-backend http-backend-dynamic \
    --instance-group=mig-dynamic-2 \
    --instance-group-zone=${ZONE2} \
    --balancing-mode=UTILIZATION \
    --max-utilization=0.8 \
    --global

# Create URL map and proxy
gcloud compute url-maps create http-lb-dynamic \
    --default-service=http-backend-dynamic

gcloud compute target-http-proxies create http-lb-proxy-dynamic \
    --url-map=http-lb-dynamic

# Create forwarding rules
gcloud compute forwarding-rules create http-lb-forwarding-rule-dynamic \
    --target-http-proxy=http-lb-proxy-dynamic \
    --ports=80 \
    --global

gcloud compute forwarding-rules create http-lb-forwarding-rule-ipv6-dynamic \
    --target-http-proxy=http-lb-proxy-dynamic \
    --ports=80 \
    --ip-version=IPV6 \
    --global

# Get LB IP
LB_IP=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule-dynamic --global --format="value(IPAddress)")
echo "Load Balancer IP: $LB_IP"

# Task 6: Stress Test Setup
# Select a zone different from the MIG zones for stress test
STRESS_ZONE=$(gcloud compute zones list --filter="region=$REGION1" --format="value(name)" | grep -v "$ZONE1" | shuf -n 1)

echo "Creating stress-test VM in $STRESS_ZONE..."
gcloud compute instances create stress-test-dynamic \
    --zone=${STRESS_ZONE} \
    --machine-type=e2-micro \
    --image=mywebserver-dynamic

echo "Waiting for resources to stabilize..."
sleep 120

# Final output
echo "Setup complete!"
echo "To stress test, SSH into the stress-test VM and run:"
echo "gcloud compute ssh stress-test-dynamic --zone=$STRESS_ZONE --command='export LB_IP=$LB_IP && ab -n 500000 -c 1000 http://\$LB_IP/'"

echo "Monitoring commands:"
echo "gcloud compute backend-services get-health http-backend-dynamic --global"
echo "gcloud compute instance-groups list-instances mig-dynamic-1 --zone=$ZONE1"
echo "gcloud compute instance-groups list-instances mig-dynamic-2 --zone=$ZONE2"
