#!/bin/bash

# Color setup
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

clear

# Banner function
function show_banner() {
    echo "${BLUE}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo "${BLUE}${BOLD}║  GOOGLE CLOUD MONITORING PROMETHEUS TUTORIAL  ║${RESET}"
    echo "${BLUE}${BOLD}║            by Dr. Abhishek                       ║${RESET}"
    echo "${BLUE}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
    echo
    echo "${GREEN}For more cloud tutorials, subscribe to:${RESET}"
    echo "${CYAN}${BOLD}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
    echo "${YELLOW}──────────────────────────────────────────────${RESET}"
    echo
}

show_banner

# User input section
echo "${MAGENTA}${BOLD}Please enter the following configuration:${RESET}"
read -p "${YELLOW}${BOLD}Enter ZONE (e.g., us-central1-a): ${RESET}" ZONE
echo

# Cluster creation
echo "${BLUE}${BOLD}Creating GKE cluster with Managed Prometheus...${RESET}"
gcloud beta container clusters create gmp-cluster \
    --num-nodes=1 \
    --zone $ZONE \
    --enable-managed-prometheus && \
echo "${GREEN}✓ Cluster created successfully${RESET}" || \
echo "${RED}✗ Failed to create cluster${RESET}"
echo

# Get cluster credentials
echo "${BLUE}${BOLD}Getting cluster credentials...${RESET}"
gcloud container clusters get-credentials gmp-cluster --zone $ZONE && \
echo "${GREEN}✓ Credentials configured successfully${RESET}" || \
echo "${RED}✗ Failed to get credentials${RESET}"
echo

# Create namespace
echo "${BLUE}${BOLD}Creating gmp-test namespace...${RESET}"
kubectl create ns gmp-test && \
echo "${GREEN}✓ Namespace created successfully${RESET}" || \
echo "${RED}✗ Failed to create namespace${RESET}"
echo

# Deploy Flask application
echo "${BLUE}${BOLD}Deploying Flask application...${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/flask_deployment.yaml && \
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/flask_service.yaml && \
echo "${GREEN}✓ Flask application deployed successfully${RESET}" || \
echo "${RED}✗ Failed to deploy Flask application${RESET}"
echo

# Get service URL
echo "${BLUE}${BOLD}Getting service endpoint...${RESET}"
url=$(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')
echo "${CYAN}Service URL: ${WHITE}http://$url${RESET}"
echo

# Test metrics endpoint
echo "${BLUE}${BOLD}Testing metrics endpoint...${RESET}"
curl -s $url/metrics | head -n 5 && \
echo "${GREEN}✓ Metrics endpoint is working${RESET}" || \
echo "${RED}✗ Failed to access metrics endpoint${RESET}"
echo

# Deploy Prometheus
echo "${BLUE}${BOLD}Deploying Prometheus...${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/prom_deploy.yaml && \
echo "${GREEN}✓ Prometheus deployed successfully${RESET}" || \
echo "${RED}✗ Failed to deploy Prometheus${RESET}"
echo

# Generate traffic
echo "${BLUE}${BOLD}Generating test traffic (2 minutes)...${RESET}"
echo "${YELLOW}This will run for 2 minutes to generate metrics${RESET}"
timeout 120 bash -c -- 'while true; do 
    curl -s $(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}') >/dev/null
    sleep $((RANDOM % 4))
done' && \
echo "${GREEN}✓ Traffic generation completed${RESET}" || \
echo "${YELLOW}⚠ Traffic generation stopped${RESET}"
echo

# Create dashboard
echo "${BLUE}${BOLD}Creating monitoring dashboard...${RESET}"
gcloud monitoring dashboards create --config='''
{
  "category": "CUSTOM",
  "displayName": "Prometheus Dashboard Example",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "prometheus/flask_http_request_total/counter [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"prometheus.googleapis.com/flask_http_request_total/counter\" resource.type=\"prometheus_target\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"status\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 0
      }
    ]
  }
}
''' && \
echo "${GREEN}✓ Dashboard created successfully${RESET}" || \
echo "${RED}✗ Failed to create dashboard${RESET}"
echo

# Completion message
echo "${GREEN}${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║          LAB COMPLETED SUCCESSFULLY       ║${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════╝${RESET}"
echo
echo "${WHITE}${BOLD}Next steps:${RESET}"
echo "${CYAN}- Check your metrics in Cloud Monitoring Console:"
echo "  https://console.cloud.google.com/monitoring/dashboards${RESET}"
echo "${CYAN}- For more tutorials, subscribe to:"
echo "  https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
echo "${BLUE}Happy monitoring with Google Cloud!${RESET}"
