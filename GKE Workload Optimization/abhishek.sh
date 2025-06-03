#!/bin/bash

# Enhanced Color Definitions
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Display Header
clear
echo "${YELLOW}${BOLD}================================================${RESET}"
echo "${YELLOW}${BOLD}   DR. ABHISHEK'S GKE DEPLOYMENT LAB           ${RESET}"
echo "${YELLOW}${BOLD}================================================${RESET}"
echo "${BLUE}YouTube Channel: https://www.youtube.com/@drabhishek.5460${RESET}"
echo "${CYAN}Video Tutorials: https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo

# Get Zone Input
echo "${CYAN}${BOLD}Step 1: Please enter your preferred zone (e.g., us-central1-a):${RESET}"
read ZONE
export ZONE
echo "${GREEN}✓ Zone set to: ${ZONE}${RESET}"
echo

# Initialize Project
echo "${CYAN}${BOLD}Step 2: Initializing Google Cloud Project...${RESET}"
gcloud config set compute/zone $ZONE
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN}✓ Project initialized: ${PROJECT_ID}${RESET}"
echo

# Create GKE Cluster
echo "${CYAN}${BOLD}Step 3: Creating GKE Cluster with 3 nodes...${RESET}"
gcloud container clusters create test-cluster --num-nodes=3 --enable-ip-alias
echo "${GREEN}✓ Cluster 'test-cluster' created successfully${RESET}"
echo

# Deploy Frontend Application
echo "${CYAN}${BOLD}Step 4: Deploying Frontend Application...${RESET}"
cat << EOF > gb_frontend_pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: gb-frontend
  name: gb-frontend
spec:
    containers:
    - name: gb-frontend
      image: gcr.io/google-samples/gb-frontend-amd64:v5
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
      ports:
      - containerPort: 80
EOF

kubectl apply -f gb_frontend_pod.yaml
echo "${GREEN}✓ Frontend pod deployed${RESET}"
echo

# Create ClusterIP Service
echo "${CYAN}${BOLD}Step 5: Creating ClusterIP Service...${RESET}"
cat << EOF > gb_frontend_cluster_ip.yaml
apiVersion: v1
kind: Service
metadata:
  name: gb-frontend-svc
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
spec:
  type: ClusterIP
  selector:
    app: gb-frontend
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
EOF

kubectl apply -f gb_frontend_cluster_ip.yaml
echo "${GREEN}✓ ClusterIP service created${RESET}"
echo

# Create Ingress
echo "${CYAN}${BOLD}Step 6: Creating Ingress...${RESET}"
cat << EOF > gb_frontend_ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gb-frontend-ingress
spec:
  defaultBackend:
    service:
      name: gb-frontend-svc
      port:
        number: 80
EOF

kubectl apply -f gb_frontend_ingress.yaml
echo "${GREEN}✓ Ingress created${RESET}"
echo

# Wait for resources
echo "${YELLOW}${BOLD}Waiting for resources to stabilize (70 seconds)...${RESET}"
sleep 70
echo "${GREEN}✓ Resources stabilized${RESET}"
echo

# Check Backend Health
echo "${CYAN}${BOLD}Step 7: Checking Backend Service Health...${RESET}"
BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global
echo "${GREEN}✓ Backend health checked${RESET}"
echo

# Get Ingress Details
echo "${CYAN}${BOLD}Step 8: Retrieving Ingress Details...${RESET}"
kubectl get ingress gb-frontend-ingress
echo "${GREEN}✓ Ingress details retrieved${RESET}"
echo

# Task 1 Confirmation
echo "${MAGENTA}${BOLD}Please verify Task 1 completion before proceeding${RESET}"
while true; do
    read -p "${YELLOW}Have you checked the progress for Task 1? (Y/N): ${RESET}" user_input
    case $user_input in
        [Yy]|[Yy][Ee][Ss])
            echo "${GREEN}Proceeding to next steps...${RESET}"
            break
            ;;
        [Nn]|[Nn][Oo])
            echo "${RED}Please check Task 1 progress before continuing${RESET}"
            ;;
        *)
            echo "${RED}Invalid input. Please enter Y or N.${RESET}"
            ;;
    esac
done
echo

# Deploy Locust Load Testing
echo "${CYAN}${BOLD}Step 9: Deploying Locust Load Testing...${RESET}"
gsutil -m cp -r gs://spls/gsp769/locust-image .
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image
gsutil cp gs://spls/gsp769/locust_deploy_v2.yaml .
sed 's/${GOOGLE_CLOUD_PROJECT}/'$GOOGLE_CLOUD_PROJECT'/g' locust_deploy_v2.yaml | kubectl apply -f -
echo "${GREEN}✓ Locust deployed${RESET}"
echo

# Liveness Probe Demo
echo "${CYAN}${BOLD}Step 10: Demonstrating Liveness Probe...${RESET}"
cat << EOF > liveness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: liveness-probe
  name: liveness-demo-pod
spec:
  containers:
  - name: liveness-demo-pod
    image: centos
    args:
    - /bin/sh
    - -c
    - touch /tmp/alive; sleep infinity
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/alive
      initialDelaySeconds: 5
      periodSeconds: 10
EOF

kubectl apply -f liveness-demo.yaml
sleep 10
kubectl describe pod liveness-demo-pod
kubectl exec liveness-demo-pod -- rm /tmp/alive
sleep 10
kubectl describe pod liveness-demo-pod
echo "${GREEN}✓ Liveness probe demonstrated${RESET}"
echo

# Readiness Probe Demo
echo "${CYAN}${BOLD}Step 11: Demonstrating Readiness Probe...${RESET}"
cat << EOF > readiness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: readiness-probe
  name: readiness-demo-pod
spec:
  containers:
  - name: readiness-demo-pod
    image: nginx
    ports:
    - containerPort: 80
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthz
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-demo-svc
  labels:
    demo: readiness-probe
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    demo: readiness-probe
EOF

kubectl apply -f readiness-demo.yaml
sleep 20
kubectl exec readiness-demo-pod -- touch /tmp/healthz
sleep 10
kubectl describe pod readiness-demo-pod | grep ^Conditions -A 5
echo "${GREEN}✓ Readiness probe demonstrated${RESET}"
echo

# Frontend Deployment
echo "${CYAN}${BOLD}Step 12: Creating Frontend Deployment...${RESET}"
kubectl delete pod gb-frontend
cat << EOF > gb_frontend_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gb-frontend
  labels:
    run: gb-frontend
spec:
  replicas: 5
  selector:
    matchLabels:
      run: gb-frontend
  template:
    metadata:
      labels:
        run: gb-frontend
    spec:
      containers:
        - name: gb-frontend
          image: gcr.io/google-samples/gb-frontend-amd64:v5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
          ports:
            - containerPort: 80
              protocol: TCP
EOF

kubectl apply -f gb_frontend_deployment.yaml
echo "${GREEN}✓ Frontend deployment created${RESET}"
echo

# Cleanup
SCRIPT_NAME="abhishek.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo "${RED}${BOLD}Removing temporary script for security...${RESET}"
    rm -- "$SCRIPT_NAME"
fi

# Completion Message
echo "${MAGENTA}${BOLD}============================================${RESET}"
echo "${MAGENTA}${BOLD}   GKE DEPLOYMENT LAB COMPLETED SUCCESSFULLY!${RESET}"
echo "${MAGENTA}${BOLD}============================================${RESET}"
echo
echo "${GREEN}${BOLD}Congratulations on completing the lab!${RESET}"
echo
echo "${BLUE}${BOLD}For more cloud tutorials:${RESET}"
echo "${CYAN}Subscribe to Dr. Abhishek's YouTube Channel:${RESET}"
echo "${YELLOW}https://www.youtube.com/@drabhishek.5460${RESET}"
echo "${CYAN}Video Tutorials:${RESET}"
echo "${YELLOW}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
