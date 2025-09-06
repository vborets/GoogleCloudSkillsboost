#!/bin/bash
set -euo pipefail



# --- Colors & formatting ---
COLOR_RESET=$'\033[0m'
BOLD=$'\033[1m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'

info() { printf "%b\n" "${CYAN}${BOLD}$*${COLOR_RESET}"; }
ok()   { printf "%b\n" "${GREEN}${BOLD}$*${COLOR_RESET}"; }
warn() { printf "%b\n" "${YELLOW}${BOLD}$*${COLOR_RESET}"; }
err()  { printf "%b\n" "${RED}${BOLD}$*${COLOR_RESET}"; }

# YouTube channel (exact URL provided)
CHANNEL_URL="https://www.youtube.com/@drabhishek.5460/videos"

# --- Spinner helpers ---
_spinner_pid=0
start_spinner(){
  local msg="$1"
  local delay=0.08
  local spinchars=('/' '-' '\' '|')
  printf "%b" "${BLUE}${BOLD}${msg}... ${COLOR_RESET}"
  (
    i=0
    while true; do
      printf "%s" "${spinchars[i%4]}"
      sleep "$delay"
      printf "\b"
      i=$((i+1))
    done
  ) &
  _spinner_pid=$!
  disown
}
stop_spinner(){
  if [ "$_spinner_pid" -ne 0 ]; then
    kill "$_spinner_pid" >/dev/null 2>&1 || true
    wait "$_spinner_pid" 2>/dev/null || true
    _spinner_pid=0
    printf "%b\n" " ${GREEN}${BOLD}done${COLOR_RESET}"
  fi
}

# --- deploy retry wrapper ---
deploy_with_retry(){
  local name="$1"; shift
  local attempts=0
  local max_attempts=5
  while [ $attempts -lt $max_attempts ]; do
    attempts=$((attempts+1))
    warn "Attempt ${attempts}: Deploying ${name}"
    start_spinner "deploying ${name} (attempt ${attempts})"
    if gcloud functions deploy "${name}" "$@"; then
      stop_spinner
      ok "${name} deployed!"
      return 0
    else
      stop_spinner
      warn "Deploy failed for ${name} (attempt ${attempts})"
      if [ $attempts -lt $max_attempts ]; then
        warn "Retrying in 30s..."
        sleep 30
      fi
    fi
  done
  err "Failed to deploy ${name} after ${max_attempts} attempts"
  return 1
}

# ---------------------------
# Header / Welcome banner
# ---------------------------
clear
printf "%b\n" "${MAGENTA}${BOLD}=========================================================${COLOR_RESET}"
printf "%b\n" "${MAGENTA}${BOLD}    Welcome to Dr Abhishek Cloud Tutorial — Let's learn GCP!   ${COLOR_RESET}"
printf "%b\n" "${MAGENTA}${BOLD}=========================================================${COLOR_RESET}"
printf "\n"
printf "%b\n" "${YELLOW}${BOLD}Channel:${COLOR_RESET} ${BLUE}${CHANNEL_URL}${COLOR_RESET}"
printf "\n"
printf "%b\n" "${YELLOW}${BOLD}If you find this helpful, please consider subscribing!${COLOR_RESET}"
printf "\n"

# ---------------------------
# Detect project, region, zone
# ---------------------------
info "Detecting Cloud project, region and zone..."
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
if [ -z "${PROJECT_ID}" ]; then
  err "No gcloud project configured. Run 'gcloud config set project PROJECT_ID' and re-run."
  exit 1
fi
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:${PROJECT_ID}" --format='value(project_number)')
# Try to read metadata keys set by the lab, fallback to us-east1/us-east1-d
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null || true)
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null || true)
: "${REGION:=us-east1}"
: "${ZONE:=us-east1-d}"

ok "Project: ${PROJECT_ID} (${PROJECT_NUMBER})"
ok "Region: ${REGION}"
ok "Zone: ${ZONE}"

# ---------------------------
# Task 1: Enable APIs
# ---------------------------
info "Enabling required APIs (this may take a minute)..."
start_spinner "Enabling APIs"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  osconfig.googleapis.com \
  pubsub.googleapis.com \
  cloudaicompanion.googleapis.com \
  --project "${PROJECT_ID}" >/dev/null 2>&1 || true
stop_spinner
ok "APIs enabled (or request submitted)."

# Set default region/zone in gcloud config
gcloud config set compute/region "${REGION}" >/dev/null || true
gcloud config set compute/zone "${ZONE}" >/dev/null || true

# ---------------------------
# Task 2: Create HTTP function
# ---------------------------
info "Task 2: Create HTTP function (nodejs)"

mkdir -p ~/hello-http && cd ~/hello-http
cat <<'EOF' > index.js
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOF

cat <<'EOF' > package.json
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_with_retry nodejs-http-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloWorld \
  --source . \
  --region "${REGION}" \
  --trigger-http \
  --timeout 600s \
  --max-instances 1 \
  --quiet

info "Testing nodejs-http-function (call)"
gcloud functions call nodejs-http-function --gen2 --region "${REGION}" || true

# ---------------------------
# Task 3: Create Cloud Storage function
# ---------------------------
info "Task 3: Create Cloud Storage function (nodejs)"

SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p "${PROJECT_NUMBER}")
info "Granting roles/pubsub.publisher to Storage service account: ${SERVICE_ACCOUNT}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member "serviceAccount:${SERVICE_ACCOUNT}" \
  --role roles/pubsub.publisher || true

mkdir -p ~/hello-storage && cd ~/hello-storage
cat <<'EOF' > index.js
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF

cat <<'EOF' > package.json
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

BUCKET="gs://gcf-gen2-storage-${PROJECT_ID}"
start_spinner "Creating bucket ${BUCKET}"
gsutil mb -l "${REGION}" "${BUCKET}" || true
stop_spinner

deploy_with_retry nodejs-storage-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloStorage \
  --source . \
  --region "${REGION}" \
  --trigger-bucket "${BUCKET}" \
  --trigger-location "${REGION}" \
  --max-instances 1 \
  --quiet

info "Testing storage trigger by uploading a file..."
echo "Hello World" > random.txt
gsutil cp random.txt "${BUCKET}/random.txt" || true

info "Checking storage function logs (may take a moment)..."
gcloud functions logs read nodejs-storage-function --region "${REGION}" --gen2 --limit=100 --format "value(log)" || true

# ---------------------------
# Task 4: Create Cloud Audit Logs function (VM labeler)
# ---------------------------
info "Task 4: Deploy Cloud Audit Logs function (gce-vm-labeler)"
# append auditConfigs to policy (some labs require the policy update)
gcloud projects get-iam-policy "${PROJECT_ID}" > /tmp/policy.yaml || true
cat <<'EOF' >> /tmp/policy.yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: compute.googleapis.com
EOF
start_spinner "Updating IAM policy for audit logs"
gcloud projects set-iam-policy "${PROJECT_ID}" /tmp/policy.yaml || true
stop_spinner

# grant eventarc.eventReceiver to default compute service account
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member "serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role roles/eventarc.eventReceiver || true

cd ~
if [ ! -d ~/eventarc-samples ]; then
  start_spinner "Cloning eventarc-samples"
  git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git || true
  stop_spinner
fi
cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs || true

deploy_with_retry gce-vm-labeler \
  --gen2 \
  --runtime nodejs22 \
  --entry-point labelVmCreation \
  --source . \
  --region "${REGION}" \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location "${REGION}" \
  --max-instances 1 \
  --quiet

info "Creating a test VM instance 'instance-1' in zone ${ZONE} to trigger the audit log function."
start_spinner "Creating test VM instance-1"
gcloud compute instances create instance-1 \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-osconfig=TRUE,enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring \
  --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any || true
stop_spinner

info "Describe the VM (look for labels):"
gcloud compute instances describe instance-1 --zone "${ZONE}" || true

# ---------------------------
# Task 5: Deploy different revisions (hello-world-colored)
# ---------------------------
info "Task 5: hello-world-colored revisions (Python)"
mkdir -p ~/hello-world-colored && cd ~/hello-world-colored
cat <<'EOF' > main.py
import os

color = os.environ.get('COLOR', 'white')

def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF
echo "" > requirements.txt

# First revision: orange
COLOR=orange
deploy_with_retry hello-world-colored \
  --gen2 \
  --runtime python311 \
  --entry-point hello_world \
  --source . \
  --region "${REGION}" \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars "COLOR=${COLOR}" \
  --max-instances 1 \
  --quiet

info "First revision deployed (COLOR=orange). Now updating revision to COLOR=yellow."
# Second revision: yellow
COLOR=yellow
deploy_with_retry hello-world-colored \
  --gen2 \
  --runtime python311 \
  --entry-point hello_world \
  --source . \
  --region "${REGION}" \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars "COLOR=${COLOR}" \
  --max-instances 1 \
  --quiet

# ---------------------------
# Task 6: Set minimum instances (slow-function)
# ---------------------------
info "Task 6: min-instances (slow-function - Go)"

mkdir -p ~/min-instances && cd ~/min-instances
cat <<'EOF' > main.go
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF
cat <<'EOF' > go.mod
module example.com/mod

go 1.23
EOF

deploy_with_retry slow-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region "${REGION}" \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4 \
  --quiet

info "Test slow-function (first call may exhibit ~10s cold start)"
gcloud functions call slow-function --gen2 --region "${REGION}" || true

info "Redeploying slow-function with --min-instances=1 to reduce cold starts."
deploy_with_retry slow-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source . \
  --region "${REGION}" \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 \
  --quiet

info "Test slow-function again (cold starts should be reduced)"
gcloud functions call slow-function --gen2 --region "${REGION}" || true

# ---------------------------
# Task 7: Create a function with concurrency (slow-concurrent-function)
# ---------------------------
info "Task 7: concurrency - deploy slow-concurrent-function and set concurrency to 100"

# Remove old service to follow lab flow (if exists)
gcloud run services delete slow-function --region "${REGION}" --quiet || true

deploy_with_retry slow-concurrent-function \
  --gen2 \
  --runtime go123 \
  --entry-point HelloWorld \
  --source ~/min-instances \
  --region "${REGION}" \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 \
  --quiet

# Wait briefly for underlying Cloud Run service to exist
sleep 5

info "Attempting to set Cloud Run service concurrency to 100"
if gcloud run services update slow-concurrent-function --region "${REGION}" --concurrency=100 --project="${PROJECT_ID}" --quiet 2>/dev/null; then
  ok "Concurrency updated to 100"
else
  warn "Could not set concurrency via gcloud run (try via Console)."
fi

# Install hey (if not present) and run tests
if ! command -v hey >/dev/null 2>&1; then
  info "Installing hey for benchmarking..."
  sudo apt-get update -y >/dev/null || true
  sudo apt-get install -y hey || true
fi

SLOW_URL=$(gcloud functions describe slow-function --region "${REGION}" --gen2 --format="value(serviceConfig.uri)" || true)
SLOW_CONCURRENT_URL=$(gcloud functions describe slow-concurrent-function --region "${REGION}" --gen2 --format="value(serviceConfig.uri)" || true)

if [ -n "${SLOW_URL}" ]; then
  info "Running hey -n 10 -c 10 against slow-function"
  hey -n 10 -c 10 "${SLOW_URL}" || true
else
  warn "slow-function URL not found; skip hey test for slow-function."
fi

if [ -n "${SLOW_CONCURRENT_URL}" ]; then
  info "Running hey -n 10 -c 10 against slow-concurrent-function (concurrency=100)"
  hey -n 10 -c 10 "${SLOW_CONCURRENT_URL}" || true
else
  warn "slow-concurrent-function URL not found; skip hey test for concurrent function."
fi

# ---------------------------
# Final summary & CTA
# ---------------------------
ok "All tasks attempted. Summary:"
printf " - Project: %s\n - Region: %s\n - Zone: %s\n" "${PROJECT_ID}" "${REGION}" "${ZONE}"
printf " - HTTP function: nodejs-http-function (region %s)\n" "${REGION}"
printf " - Storage function: nodejs-storage-function (bucket: %s)\n" "${BUCKET}"
printf " - Audit Log function: gce-vm-labeler (region %s)\n" "${REGION}"
printf " - Hello color function: hello-world-colored (revisions orange->yellow)\n"
printf " - Slow function: slow-function (min-instances=1)\n"
printf " - Concurrent function: slow-concurrent-function (concurrency attempted=100)\n"

printf "\n"
printf "%b\n" "${MAGENTA}${BOLD}If this helped you, please visit and subscribe: ${COLOR_RESET}${BLUE}${CHANNEL_URL}${COLOR_RESET}"
printf "%b\n" "${YELLOW}${BOLD}Thank you for using Dr Abhishek Cloud Tutorial — happy building!${COLOR_RESET}"
printf "\n"

# End
