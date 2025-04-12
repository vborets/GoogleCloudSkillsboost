#!/bin/bash

# Professional Color Scheme
HEADER_COLOR=$'\033[38;5;54m'       # Deep purple
TITLE_COLOR=$'\033[38;5;93m'         # Bright purple
PROMPT_COLOR=$'\033[38;5;178m'       # Gold
ACTION_COLOR=$'\033[38;5;44m'        # Teal
SUCCESS_COLOR=$'\033[38;5;46m'       # Bright green
WARNING_COLOR=$'\033[38;5;196m'      # Bright red
LINK_COLOR=$'\033[38;5;27m'          # Blue
TEXT_COLOR=$'\033[38;5;255m'         # Bright white

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear


echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${TITLE_COLOR}${BOLD_TEXT}       🎓 DR. ABHISHEK'S CLOUD TUTORIAL      ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}This lab demonstrates a complete Dataflow pipeline from Pub/Sub to${RESET_FORMAT}"
echo "${TEXT_COLOR}Cloud Storage using Google Cloud services.${RESET_FORMAT}"
echo

# Function to display messages with formatting
print_message() {
    local color=$1
    local emoji=$2
    local message=$3
    echo -e "${color}${BOLD_TEXT}${emoji}  ${message}${RESET_FORMAT}"
}

# Get region input with validation
while true; do
    read -p "${PROMPT_COLOR}${BOLD_TEXT}🌍 Enter your GCP region (e.g., us-central1): ${RESET_FORMAT}" REGION
    if [[ -z "$REGION" ]]; then
        print_message "$WARNING_COLOR" "⚠" "Region cannot be empty. Please try again."
    else
        export REGION=$REGION
        gcloud config set compute/region $REGION
        print_message "$SUCCESS_COLOR" "✓" "Region set to: $REGION"
        break
    fi
done
echo

# API Configuration
print_message "$ACTION_COLOR" "⚙️" "Configuring required APIs..."
gcloud services disable dataflow.googleapis.com --quiet
gcloud services enable dataflow.googleapis.com cloudscheduler.googleapis.com --quiet
print_message "$SUCCESS_COLOR" "✓" "APIs configured successfully"
echo

# Get project details
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="${PROJECT_ID}-bucket"
TOPIC_ID="data-pipeline-topic"

print_message "$ACTION_COLOR" "🆔" "Using Project ID: $PROJECT_ID"
print_message "$ACTION_COLOR" "🪣" "Bucket Name: $BUCKET_NAME"
print_message "$ACTION_COLOR" "📨" "Topic ID: $TOPIC_ID"
echo

# Resource Creation
print_message "$ACTION_COLOR" "🛠️" "Creating infrastructure resources..."

print_message "$TEXT_COLOR" "🪣" "Creating Cloud Storage bucket..."
gsutil mb -l $REGION gs://$BUCKET_NAME

print_message "$TEXT_COLOR" "📨" "Creating Pub/Sub topic..."
gcloud pubsub topics create $TOPIC_ID

print_message "$TEXT_COLOR" "🚀" "Setting up App Engine..."
case "$REGION" in
    "us-central1") gcloud app create --region=us-central --quiet ;;
    "europe-west1") gcloud app create --region=europe-west --quiet ;;
    *) gcloud app create --region="$REGION" --quiet ;;
esac
print_message "$SUCCESS_COLOR" "✓" "Infrastructure resources created successfully"
echo

# Scheduler Configuration
print_message "$ACTION_COLOR" "⏰" "Configuring Cloud Scheduler..."
gcloud scheduler jobs create pubsub data-publisher \
    --schedule="* * * * *" \
    --topic=$TOPIC_ID \
    --message-body="Hello from Dr. Abhishek's Workshop!" \
    --location=$REGION \
    --quiet

print_message "$WARNING_COLOR" "⏳" "Waiting for scheduler initialization..."
sleep 90

print_message "$TEXT_COLOR" "🔧" "Testing message publishing..."
gcloud scheduler jobs run data-publisher --location=$REGION --quiet
print_message "$SUCCESS_COLOR" "✓" "Scheduler configured successfully"
echo

# Dataflow Pipeline Setup
print_message "$ACTION_COLOR" "🌊" "Preparing Dataflow pipeline script..."

cat > run_dataflow_pipeline.sh <<EOF
#!/bin/bash

# Environment configuration
export PROJECT_ID=$PROJECT_ID
export REGION=$REGION
export TOPIC_ID=$TOPIC_ID
export BUCKET_NAME=$BUCKET_NAME

# Clone samples repository
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics

# Install dependencies
pip install -U -r requirements.txt

# Execute pipeline
python PubSubToGCS.py \\
    --project=\$PROJECT_ID \\
    --region=\$REGION \\
    --input_topic=projects/\$PROJECT_ID/topics/\$TOPIC_ID \\
    --output_path=gs://\$BUCKET_NAME/samples/output \\
    --runner=DataflowRunner \\
    --window_size=2 \\
    --num_shards=2 \\
    --temp_location=gs://\$BUCKET_NAME/temp
EOF

chmod +x run_dataflow_pipeline.sh
print_message "$SUCCESS_COLOR" "✓" "Pipeline script prepared"
echo

# Docker Execution
print_message "$ACTION_COLOR" "🐳" "Running pipeline in Docker container..."
docker run -it \
    -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID \
    -e BUCKET_NAME=$BUCKET_NAME \
    -e PROJECT_ID=$PROJECT_ID \
    -e REGION=$REGION \
    -e TOPIC_ID=$TOPIC_ID \
    -v $(pwd)/run_dataflow_pipeline.sh:/run_dataflow_pipeline.sh \
    python:3.7 \
    /bin/bash -c "/run_dataflow_pipeline.sh"
print_message "$SUCCESS_COLOR" "✓" "Pipeline execution initiated"
echo

# Completion message
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${SUCCESS_COLOR}${BOLD_TEXT}          🎉 LAB COMPLETED SUCCESSFULLY! 🎉         ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}${BOLD_TEXT}You've successfully completed these operations:${RESET_FORMAT}"
echo "${TEXT_COLOR}• Configured Pub/Sub messaging system"
echo "• Established Cloud Storage integration"
echo "• Created a scheduled data pipeline"
echo "• Implemented Dataflow processing${RESET_FORMAT}"
echo
echo -e "${PROMPT_COLOR}${BOLD_TEXT}💡 Continue learning at: ${LINK_COLOR}https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo "${PROMPT_COLOR}${BOLD_TEXT}   Don't forget to like and subscribe!${RESET_FORMAT}"
echo
