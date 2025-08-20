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
echo "    SUBSCRIBE for more Kubernetes and Cloud Computing tutorials!"
echo "=================================================================="
echo ""
sleep 3

echo "Starting Google Kubernetes Engine lab setup..."
echo "This comprehensive script will complete ALL lab tasks automatically"
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
ls

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
progress "Creating fortune-app pod..."
kubectl create -f pods/fortune-app.yaml || handle_error "Failed to create fortune-app pod"
kubectl get pods

progress "Describing fortune-app pod..."
kubectl describe pods fortune-app

# Task: Interact with Pods (Port Forwarding)
progress "Setting up port forwarding for fortune-app..."
echo "Note: Port forwarding runs in background for testing"
kubectl port-forward fortune-app 10080:8080 &
PORT_FORWARD_PID=$!
sleep 5

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
kubectl logs fortune-app

# Task: Create Secure Fortune Pod and Service
progress "Creating TLS certificates secret..."
kubectl create secret generic tls-certs --from-file tls/ || handle_error "Failed to create TLS secret"

progress "Creating nginx proxy configuration..."
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf || handle_error "Failed to create configmap"

progress "Creating secure-fortune pod..."
kubectl create -f pods/secure-fortune.yaml || handle_error "Failed to create secure-fortune pod"

progress "Creating fortune-app service..."
kubectl create -f services/fortune-app.yaml || handle_error "Failed to create fortune-app service"

progress "Creating firewall rule for port 31000..."
gcloud compute firewall-rules create allow-fortune-nodeport --allow=tcp:31000 || handle_error "Failed to create firewall rule"

# Task: Add Labels to Pods
progress "Adding 'secure=enabled' label to secure-fortune pod..."
kubectl label pods secure-fortune 'secure=enabled' || handle_error "Failed to label pod"
kubectl get pods secure-fortune --show-labels

progress "Checking service endpoints..."
kubectl describe services fortune-app | grep Endpoints || handle_error "No endpoints found"

# Test secure fortune service
progress "Testing secure fortune service externally..."
EXTERNAL_IP=$(gcloud compute instances list --format="value(EXTERNAL_IP)" | head -n1)
if [ -n "$EXTERNAL_IP" ]; then
    curl -k https://$EXTERNAL_IP:31000 || handle_error "Secure fortune service not accessible"
else
    handle_error "Could not get external IP"
fi

# Task: Create Microservices Deployments - FIXED VERSION
progress "Creating auth microservice deployment..."
kubectl create -f deployments/auth.yaml || {
    handle_error "Failed to create auth deployment"
    # Alternative approach if YAML file has issues
    kubectl create deployment auth --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/auth-service:1.0.0 --port=8080
}

progress "Creating auth service..."
kubectl create -f services/auth.yaml || {
    handle_error "Failed to create auth service"
    kubectl expose deployment auth --port=80 --target-port=8080 --type=ClusterIP
}

progress "Creating hello service deployment..."
# Check if hello.yaml exists, otherwise use alternative approach
if [ -f "deployments/hello.yaml" ]; then
    kubectl create -f deployments/hello.yaml || handle_error "Failed to create hello deployment"
else
    progress "Creating hello deployment using alternative method..."
    kubectl create deployment hello --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/hello-app:1.0.0 --port=8080
fi

progress "Creating hello service..."
if [ -f "services/hello.yaml" ]; then
    kubectl create -f services/hello.yaml || handle_error "Failed to create hello service"
else
    kubectl expose deployment hello --port=80 --target-port=8080 --type=ClusterIP
fi

progress "Creating frontend configuration..."
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf || handle_error "Failed to create frontend configmap"

progress "Creating frontend deployment..."
if [ -f "deployments/frontend.yaml" ]; then
    kubectl create -f deployments/frontend.yaml || {
        handle_error "Failed to create frontend deployment from YAML"
        # Alternative frontend deployment
        kubectl create deployment frontend --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/frontend:1.0.0 --port=80
    }
else
    kubectl create deployment frontend --image=us-central1-docker.pkg.dev/qwiklabs-resources/spl-lab-apps/frontend:1.0.0 --port=80
fi

progress "Creating frontend service..."
if [ -f "services/frontend.yaml" ]; then
    kubectl create -f services/frontend.yaml || {
        handle_error "Failed to create frontend service from YAML"
        kubectl expose deployment frontend --port=80 --target-port=80 --type=LoadBalancer
    }
else
    kubectl expose deployment frontend --port=80 --target-port=80 --type=LoadBalancer
fi

# Wait for frontend service to get external IP
progress "Waiting for frontend external IP assignment..."
sleep 60  # Longer wait for LoadBalancer

progress "Checking frontend service status..."
kubectl get services frontend

# Test frontend service
FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
    progress "Testing frontend service at https://$FRONTEND_IP"
    curl -k https://$FRONTEND_IP || handle_error "Frontend service not responding"
else
    progress "Frontend IP not yet assigned, checking status..."
    kubectl describe service frontend
fi

# Task: Create Monolith
progress "Creating monolith application..."
kubectl create -f pods/monolith.yaml || handle_error "Failed to create monolith pod"
kubectl get pods

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null

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
    echo "1. Visit your frontend at: https://$FRONTEND_IP"
else
    echo "1. Check frontend service: kubectl get svc frontend -w"
fi
echo "2. Test your services using the endpoints above"
echo "3. Explore Kubernetes dashboard: kubectl proxy"
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
