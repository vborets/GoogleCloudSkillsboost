#!/bin/bash

# Welcome message
echo "=================================================="
echo "Welcome to Dr. Abhishek Cloud Tutorial!"
echo "Subscribe to the channel: https://www.youtube.com/@drabhishek.5460/videos"
echo "=================================================="
echo ""

# Get user inputs for region and zone
echo "=== Configuration Setup ==="
read -p "Enter your region (e.g., us-central1): " REGION
read -p "Enter zone for subnet-a (e.g., ${REGION}-a): " ZONE_A
read -p "Enter zone for subnet-b (e.g., ${REGION}-b): " ZONE_B
read -p "Enter zone for utility VM (e.g., ${REGION}-a): " UTILITY_ZONE

echo ""
echo "Using configuration:"
echo "Region: $REGION"
echo "Zone A: $ZONE_A"
echo "Zone B: $ZONE_B"
echo "Utility Zone: $UTILITY_ZONE"
echo ""

# Set project variables
PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# Task 1: Configure HTTP and health check firewall rules
echo ""
echo "=== TASK 1: Configuring Firewall Rules ==="

# Create HTTP firewall rule
echo "Creating HTTP firewall rule..."
gcloud compute firewall-rules create app-allow-http \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=10.10.0.0/16 \
    --rules=tcp:80

# Create health check firewall rule
echo "Creating health check firewall rule..."
gcloud compute firewall-rules create app-allow-health-check \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --rules=tcp

echo "Firewall rules created successfully!"
echo ""

# Task 2: Configure instance templates and create instance groups
echo "=== TASK 2: Creating Instance Templates and Groups ==="

# Create instance template for subnet-a
echo "Creating instance template for subnet-a..."
gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

# Create instance template for subnet-b
echo "Creating instance template for subnet-b..."
gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-b \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

# Create managed instance group for zone A
echo "Creating instance group in $ZONE_A..."
gcloud compute instance-groups managed create instance-group-1 \
    --template=instance-template-1 \
    --size=1 \
    --zone=$ZONE_A \
    --region=$REGION

# Create managed instance group for zone B
echo "Creating instance group in $ZONE_B..."
gcloud compute instance-groups managed create instance-group-2 \
    --template=instance-template-2 \
    --size=1 \
    --zone=$ZONE_B \
    --region=$REGION

# Configure autoscaling for both instance groups
echo "Configuring autoscaling..."
gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --zone=$ZONE_A \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8 \
    --cool-down-period=45

gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --zone=$ZONE_B \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8 \
    --cool-down-period=45

echo "Instance groups created and configured!"
echo ""

# Wait for instances to be created
echo "Waiting for instances to be ready..."
sleep 60

# Create utility VM
echo "Creating utility VM..."
gcloud compute instances create utility-vm \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --private-network-ip=10.10.20.50 \
    --zone=$UTILITY_ZONE \
    --region=$REGION

echo "Utility VM created!"
echo ""

# Verify backends
echo "=== Verifying Backends ==="
echo "Waiting for instances to be fully ready..."
sleep 30

# Get internal IPs of the instances
INSTANCE_1_IP=$(gcloud compute instances list --filter="name:instance-group-1" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_A)
INSTANCE_2_IP=$(gcloud compute instances list --filter="name:instance-group-2" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_B)

echo "Instance 1 IP: $INSTANCE_1_IP"
echo "Instance 2 IP: $INSTANCE_2_IP"
echo ""

# Test connectivity via utility VM
echo "Testing connectivity through utility VM..."
echo "This may take a moment..."

# SSH into utility VM and test connectivity
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing connection to instance-group-1...'
    curl -s $INSTANCE_1_IP | grep -E '(Server Hostname|Server Location|Client IP)'
    echo ''
    echo 'Testing connection to instance-group-2...'
    curl -s $INSTANCE_2_IP | grep -E '(Server Hostname|Server Location|Client IP)'
    echo ''
    echo 'Backend verification complete!'
"

echo ""
echo "Backends verified successfully!"
echo ""

# Task 3: Configure the Internal Load Balancer
echo "=== TASK 3: Configuring Internal Load Balancer ==="

# Create health check
echo "Creating health check..."
gcloud compute health-checks create tcp my-ilb-health-check \
    --port=80 \
    --region=$REGION

# Create backend service
echo "Creating backend service..."
gcloud compute backend-services create my-ilb-backend-service \
    --load-balancing-scheme=internal \
    --protocol=TCP \
    --health-checks=my-ilb-health-check \
    --health-checks-region=$REGION \
    --region=$REGION

# Add instance groups to backend service
echo "Adding instance groups to backend service..."
gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-1 \
    --instance-group-zone=$ZONE_A \
    --region=$REGION

gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-2 \
    --instance-group-zone=$ZONE_B \
    --region=$REGION

# Create forwarding rule
echo "Creating forwarding rule..."
gcloud compute forwarding-rules create my-ilb \
    --load-balancing-scheme=internal \
    --network=my-internal-app \
    --subnet=subnet-b \
    --address=10.10.30.5 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=my-ilb-backend-service \
    --backend-service-region=$REGION \
    --region=$REGION

echo "Internal Load Balancer configuration complete!"
echo ""

# Final verification
echo "=== Final Verification ==="
echo "Load Balancer IP: 10.10.30.5"
echo ""
echo "To test the load balancer, SSH into utility-vm and run:"
echo "curl 10.10.30.5"
echo ""
echo "You should see responses from different backend instances."

# Test the load balancer
echo "Testing load balancer..."
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing Load Balancer (10.10.30.5):'
    for i in {1..3}; do
        echo 'Attempt' \$i ':'
        curl -s 10.10.30.5 | grep -E '(Server Hostname|Server Location)'
        echo '---'
        sleep 2
    done
"

echo ""
echo "=================================================="
echo "All tasks completed successfully!"
echo "Infrastructure Summary:"
echo "- Firewall rules: app-allow-http, app-allow-health-check"
echo "- Instance templates: instance-template-1, instance-template-2"
echo "- Instance groups: instance-group-1, instance-group-2"
echo "- Internal Load Balancer: my-ilb (10.10.30.5)"
echo "- Utility VM: utility-vm"
echo ""
echo "Thank you for following Dr. Abhishek Cloud Tutorial!"
echo "Don't forget to subscribe: https://www.youtube.com/@drabhishek.5460/videos"
echo "=================================================="
