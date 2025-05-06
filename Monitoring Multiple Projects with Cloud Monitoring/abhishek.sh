#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome Banner
echo "${BLUE_TEXT}${BOLD_TEXT}"
echo "*****************************************************************"
echo "*                                                               *"
echo "*          Welcome to Dr. Abhishek Cloud Tutorials!             *"
echo "*                                                               *"
echo "*  Subscribe for more content:                                  *"
echo "*  https://www.youtube.com/@drabhishek.5460/videos              *"
echo "*                                                               *"
echo "*****************************************************************"
echo "${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         STARTING THE LAB          🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📌 Preparing to assign project variables...${RESET_FORMAT}"

# Spinner function
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

assign_projects() {
  echo -n "${BLUE_TEXT}${BOLD_TEXT}🔍 Fetching the list of available GCP projects...${RESET_FORMAT}"
  (PROJECT_LIST=$(gcloud projects list --format="value(projectId)") &
  spinner
  echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

  echo -n "${GREEN_TEXT}${BOLD_TEXT}✍️ Please Enter the PROJECT_2 ID: ${RESET_FORMAT}"
  read PROJECT_2

  if [[ ! "$PROJECT_LIST" =~ (^|[[:space:]])"$PROJECT_2"($|[[:space:]]) ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}❌ Invalid project ID. Please enter a valid project ID from the list.${RESET_FORMAT}"
    return 1
  fi

  echo -n "${BLUE_TEXT}${BOLD_TEXT}🔍 Selecting a different project for PROJECT_1...${RESET_FORMAT}"
  (PROJECT_1=$(echo "$PROJECT_LIST" | grep -v "^$PROJECT_2$" | head -n 1)) &
  spinner
  echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

  if [[ -z "$PROJECT_1" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}⚠️ No other project available to assign to PROJECT_1.${RESET_FORMAT}"
    return 1
  fi

  echo -n "${MAGENTA_TEXT}${BOLD_TEXT}⬆️ Exporting the selected project IDs...${RESET_FORMAT}"
  (export PROJECT_2
   export PROJECT_1) &
  spinner
  echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

  echo
  echo "${BLUE_TEXT}${BOLD_TEXT}✅ PROJECT_1 has been set to: $PROJECT_1${RESET_FORMAT}"
  echo "${MAGENTA_TEXT}${BOLD_TEXT}✅ PROJECT_2 has been set to: $PROJECT_2${RESET_FORMAT}"
}

echo "${GREEN_TEXT}${BOLD_TEXT}⚙️ Running the project assignment function...${RESET_FORMAT}"
assign_projects

echo -n "${YELLOW_TEXT}${BOLD_TEXT}🔧 Configuring gcloud to use project $PROJECT_2...${RESET_FORMAT}"
(gcloud config set project $PROJECT_2 > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

echo -n "${CYAN_TEXT}${BOLD_TEXT}🌍 Determining the default compute zone...${RESET_FORMAT}"
(export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone]")) &
spinner
echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

echo -n "${CYAN_TEXT}${BOLD_TEXT}🛠️ Creating VM instance 'instance2'...${RESET_FORMAT}"
(gcloud compute instances create instance2 \
    --zone=$ZONE \
    --machine-type=e2-medium > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Click here to monitor metrics: ${RESET_FORMAT}""https://console.cloud.google.com/monitoring/settings/metric-scope?project=$PROJECT_2"

function check_progress {
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}🤔 Have you created Group 'DemoGroup' & Uptime check? (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${CYAN_TEXT}${BOLD_TEXT}👍 Great! Proceeding to the next steps...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}✋ Please create the Group and Uptime Check, then press Y to continue.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}❓ Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚥         Please follow Video Steps.        🚥${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

check_progress

echo -n "${RED_TEXT}${BOLD_TEXT}📄 Generating monitoring policy JSON...${RESET_FORMAT}"
(cat > arcadecrew.json <<EOF_END
{
  "displayName": "Uptime Check Policy",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - Check passed",
      "conditionAbsent": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"demogroup-uptime-check-f-UeocjSHdQ\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_FRACTION_TRUE"
          }
        ],
        "duration": "300s",
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {},
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END
) &
spinner
echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

echo -n "${CYAN_TEXT}${BOLD_TEXT}📡 Creating monitoring policy...${RESET_FORMAT}"
(gcloud alpha monitoring policies create --policy-from-file="arcadecrew.json" > /dev/null 2>&1) &
spinner
echo " ${GREEN_TEXT}✓ Done!${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the tutorial? Consider subscribing to Dr. Abhishek Cloud Tutorials! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@drabhishek.5460${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Lab  completed successfully!${RESET_FORMAT}"
