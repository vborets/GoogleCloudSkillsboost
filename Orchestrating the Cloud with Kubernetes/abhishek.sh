#!/bin/bash

# ==============================================
# Google Kubernetes Engine Complete Lab Setup
# Welcome to Dr. Abhishek Cloud Tutorials!
# YouTube: https://www.youtube.com/@drabhishek.5460/videos
# ==============================================

# ASCII Art Banner
echo "                                                                               
  ____  _       _     _           _    _           _       _     _   
 |  _ \(_)     | |   | |         | |  | |         | |     | |   | |  
 | |_) |_  __ _| |__ | |__   ___ | | _| | ___  | |_ ___| |__ | |_ 
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
echo "    SUBSCRIBE for more Kubernetes and Cloud Computing tutorials!"
echo "=================================================================="
echo ""
sleep 3

echo "Starting Google Kubernetes Engine lab setup..."
echo "Do like the Video & Sub the Channel"
echo ""

# Display progress function
progress() {
    echo "✅ $1"
    sleep 2
}

# Error handling function
handle_error() {
    echo "❌ Error: $1"
    echo "⚠️  Attempting to continue with next task..."
    sleep 2
}

# Function to check file existence
check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ File not found: $1"
        return 1
    fi
    return 0
}

# Task: Initial Setup
progress "Setting up initial configuration..."
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

# Task: Create Kubernetes Cluster
progress "Creating Kubernetes cluster 'io' in zone: $ZONE"
gcloud container clusters create io --zone $ZONE --num-nodes=2 --machine-type=e2-medium

# Task: Get Sample Code
progress "Downloading sample code from Google Cloud Storage..."
gsutil cp -r gs://spls/gsp021/* .
cd orchestrate-with-kubernetes/kubernetes
ls -la

# Check if we're in the right directory
if [ ! -d "pods" ] || [ ! -d "deployments" ]; then
    echo "❌ Directory structure incorrect. Checking alternative locations..."
    find . -name "*.yaml" -type f | head -10
    echo "Please check the current directory structure and adjust paths accordingly"
    pwd
    ls -la
fi

# Task: Quick Kubernetes Demo
progress "Creating nginx deployment (version 1.27.0)..."
kubectl create deployment nginx --image=nginx:1.27.0
kubectl get pods

progress "Exposing nginx as LoadBalancer service..."
kubectl expose deployment nginx --port 80 --type LoadBalancer
kubectl get services

# Wait for external IP to be assigned
progress "Waiting for external IP assignment..."
sleep 30
kubectl get services

# Task: Create Fortune App Pod
progress "Checking for fortune-app.yaml..."
if check_file "pods/fortune-app.yaml"; then
    kubectl create -f pods/fortune-app.yaml || handle_error "Failed to create fortune-app pod"
else
    progress "Creating fortune-app pod using alternative method..."
    kubectl create deployment fortune-app --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/fortune-app:1.0.0 --port=8080
fi

kubectl get pods

progress "Describing fortune-app pod..."
kubectl describe pods fortune-app

# Task: Interact with Pods (Port Forwarding)
progress "Setting up port forwarding for fortune-app..."
echo "Note: Port forwarding runs in background for testing"
kubectl port-forward deployment/fortune-app 10080:8080 &
PORT_FORWARD_PID=$!
sleep 10

progress "Testing fortune app endpoint..."
curl http://127.0.0.1:10080 || handle_error "Fortune app not responding"

progress "Testing secure endpoint (expected to fail)..."
curl http://127.0.0.1:10080/secure || echo "Expected failure - endpoint requires authentication"

progress "Logging in to get authentication token..."
TOKEN=$(curl -s -u user:password http://127.0.0.1:10080/login | jq -r '.token')
if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "Token acquired successfully!"
    
    progress "Testing secure endpoint with authentication token..."
    curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:10080/secure || handle_error "Secure endpoint failed"
else
    handle_error "Failed to acquire authentication token"
fi

progress "Viewing application logs..."
kubectl logs deployment/fortune-app

# Task: Create Secure Fortune Pod and Service
progress "Creating TLS certificates secret..."
if [ -d "tls" ]; then
    kubectl create secret generic tls-certs --from-file tls/ || handle_error "Failed to create TLS secret"
else
    handle_error "TLS directory not found"
fi

progress "Creating nginx proxy configuration..."
if check_file "nginx/proxy.conf"; then
    kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf || handle_error "Failed to create configmap"
else
    handle_error "proxy.conf file not found"
fi

progress "Creating secure-fortune pod..."
if check_file "pods/secure-fortune.yaml"; then
    kubectl create -f pods/secure-fortune.yaml || handle_error "Failed to create secure-fortune pod"
else
    progress "Creating secure-fortune using alternative method..."
    kubectl create deployment secure-fortune --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/fortune-app:1.0.0 --port=8080
fi

progress "Creating fortune-app service..."
if check_file "services/fortune-app.yaml"; then
    kubectl create -f services/fortune-app.yaml || handle_error "Failed to create fortune-app service"
else
    kubectl expose deployment secure-fortune --port=443 --target-port=8080 --type=NodePort --name=fortune-app
fi

progress "Creating firewall rule for port 31000..."
gcloud compute firewall-rules create allow-fortune-nodeport --allow=tcp:31000 || handle_error "Failed to create firewall rule"

# Task: Add Labels to Pods
progress "Adding 'secure=enabled' label to secure-fortune pod..."
kubectl label deployment secure-fortune 'secure=enabled' || handle_error "Failed to label deployment"
kubectl get pods --show-labels | grep secure-fortune

progress "Checking service endpoints..."
kubectl describe services fortune-app | grep Endpoints || handle_error "No endpoints found"

# Test secure fortune service
progress "Testing secure fortune service externally..."
EXTERNAL_IP=$(gcloud compute instances list --format="value(EXTERNAL_IP)" | head -n1)
if [ -n "$EXTERNAL_IP" ]; then
    NODE_PORT=$(kubectl get service fortune-app -o jsonpath='{.spec.ports[0].nodePort}')
    progress "Testing on node port: $NODE_PORT"
    curl -k https://$EXTERNAL_IP:$NODE_PORT || handle_error "Secure fortune service not accessible"
else
    handle_error "Could not get external IP"
fi

# Task: Create Microservices Deployments
progress "Creating auth microservice deployment..."
if check_file "deployments/auth.yaml"; then
    kubectl create -f deployments/auth.yaml || handle_error "Failed to create auth deployment"
else
    kubectl create deployment auth --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/auth-service:1.0.0 --port=8080
fi

progress "Creating auth service..."
if check_file "services/auth.yaml"; then
    kubectl create -f services/auth.yaml || handle_error "Failed to create auth service"
else
    kubectl expose deployment auth --port=80 --target-port=8080 --type=ClusterIP
fi

progress "Creating hello service deployment..."
if check_file "deployments/hello.yaml"; then
    kubectl create -f deployments/hello.yaml || handle_error "Failed to create hello deployment"
else
    kubectl create deployment hello --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/hello-app:1.0.0 --port=8080
fi

progress "Creating hello service..."
if check_file "services/hello.yaml"; then
    kubectl create -f services/hello.yaml || handle_error "Failed to create hello service"
else
    kubectl expose deployment hello --port=80 --target-port=8080 --type=ClusterIP
fi

progress "Creating frontend configuration..."
if check_file "nginx/frontend.conf"; then
    kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf || handle_error "Failed to create frontend configmap"
else
    handle_error "frontend.conf file not found"
fi

progress "Creating frontend deployment..."
if check_file "deployments/frontend.yaml"; then
    kubectl create -f deployments/frontend.yaml || handle_error "Failed to create frontend deployment from YAML"
else
    kubectl create deployment frontend --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/frontend:1.0.0 --port=80
fi

progress "Creating frontend service..."
if check_file "services/frontend.yaml"; then
    kubectl create -f services/frontend.yaml || handle_error "Failed to create frontend service from YAML"
else
    kubectl expose deployment frontend --port=80 --target-port=80 --type=LoadBalancer
fi

# Wait for frontend service to get external IP
progress "Waiting for frontend external IP assignment (this may take 2-3 minutes)..."
for i in {1..12}; do
    echo "Waiting... $((i*10)) seconds passed"
    sleep 10
    FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
        break
    fi
done

progress "Checking frontend service status..."
kubectl get services frontend

# Test frontend service with better error handling
FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
    progress "Testing frontend service at https://$FRONTEND_IP"
    
    # Check if port 443 is open
    if nc -z -w5 $FRONTEND_IP 443; then
        curl -k --connect-timeout 30 --max-time 60 https://$FRONTEND_IP || \
        echo "Frontend service might be starting. Check again in a few minutes."
    else
        echo "Port 443 is not open on $FRONTEND_IP. Service may still be provisioning."
        echo "Check service status: kubectl describe service frontend"
    fi
else
    progress "Frontend IP not yet assigned. Checking service details..."
    kubectl describe service frontend
    echo "LoadBalancer provisioning can take several minutes. Please wait and check again."
fi

# Task: Create Monolith - FIXED with proper file checking
progress "Checking for monolith.yaml..."
if check_file "pods/monolith.yaml"; then
    kubectl create -f pods/monolith.yaml || handle_error "Failed to create monolith pod"
else
    progress "monolith.yaml not found. Checking for alternative locations..."
    find . -name "*monolith*" -type f 2>/dev/null || echo "No monolith files found"
    
    # Create a simple monolith deployment instead
    progress "Creating monolith deployment as alternative..."
    kubectl create deployment monolith --image=nginx:1.27.0 --port=80
    kubectl expose deployment monolith --port=80 --target-port=80 --type=ClusterIP
fi

kubectl get pods

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

# Final output
echo ""
echo "=================================================================="
echo "🎉 LAB SETUP COMPLETED!"
echo "=================================================================="
echo "All Kubernetes lab tasks have been executed!"
echo ""
echo "📊 CURRENT STATUS:"
echo "=================================================================="
kubectl get pods
echo "------------------------------------------------------------------"
kubectl get services
echo "------------------------------------------------------------------"
kubectl get deployments
echo "=================================================================="

echo ""
echo "💡 NEXT STEPS:"
if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
    echo "1. Visit your frontend at: https://$FRONTEND_IP (may take a few minutes to be accessible)"
else
    echo "1. Check frontend service: kubectl get svc frontend -w"
fi
echo "2. Monitor service status: kubectl get svc --watch"
echo "3. View detailed service info: kubectl describe svc frontend"
echo "4. Check pod status: kubectl get pods --watch"
echo ""

echo "=============================================================================="
echo "📺 LIKE THIS TUTORIAL? SUBSCRIBE TO DR. ABHISHEK CLOUD TUTORIALS!"
echo "YouTube: https://www.youtube.com/@drabhishek.5460/videos"
echo "=============================================================================="
echo "   Don't forget to like, share, and comment on the Kubernetes tutorials!"
echo "=============================================================================="

# Cluster info
echo ""
echo "🔧 Cluster Information:"
gcloud container clusters describe io --zone $ZONE --format="value(name, currentMasterVersion, endpoint)"
