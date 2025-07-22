
#!/bin/bash

# Welcome message
echo "============================================="
echo " Welcome to Dr. Abhishek Cloud Tutorials!    "
echo "============================================="
echo " Please like the video and subscribe to the  "
echo " channel if you find this content helpful.   "
echo "---------------------------------------------"
echo ""

# Function to show spinner while commands run
spinner() {
    local pid=$!
    local delay=0.25
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

# Prompt user for zone input
echo "Please enter your preferred zone (e.g., us-central1-a):"
read -p "Zone: " ZONE
export ZONE

echo ""
echo "Starting setup... This may take a few minutes."
echo ""

# Set project and region
export PROJECT_ID=$(gcloud config get-value project)
echo -n "Setting project $PROJECT_ID... "
gcloud config set project $PROJECT_ID > /dev/null 2>&1 &
spinner
echo "Done"

export REGION="${ZONE%-*}"
echo "Region automatically set to: $REGION"
echo ""

# Enable required services
echo -n "Enabling required Google Cloud services... "
gcloud services enable compute.googleapis.com > /dev/null 2>&1 &
gcloud services enable logging.googleapis.com > /dev/null 2>&1 &
gcloud services enable monitoring.googleapis.com > /dev/null 2>&1 &
gcloud services enable recaptchaenterprise.googleapis.com > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

# Create firewall rules
echo -n "Creating firewall rules for health checks and SSH... "
gcloud compute firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=allow-health-check > /dev/null 2>&1 &
gcloud compute firewall-rules create allow-ssh --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0 --target-tags=allow-health-check > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

# Create instance template
echo -n "Creating instance template for load balancer backend... "
gcloud compute instance-templates create lb-backend-template \
    --machine-type=n1-standard-1 \
    --region=$REGION \
    --network=default \
    --subnet=default \
    --tags=allow-health-check \
    --metadata=startup-script='#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo a2ensite default-ssl
sudo a2enmod ssl
sudo su
vm_hostname="$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname" | tee /var/www/html/index.html' > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create managed instance group
echo -n "Creating managed instance group... "
gcloud beta compute instance-groups managed create lb-backend-example --project=$PROJECT_ID --base-instance-name=lb-backend-example --template=projects/$PROJECT_ID/global/instanceTemplates/lb-backend-template --size=1 --zone=$ZONE --default-action-on-vm-failure=repair --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=PAGELESS > /dev/null 2>&1 && 
gcloud beta compute instance-groups managed set-autoscaling lb-backend-example --project=$PROJECT_ID --zone=$ZONE --mode=off --min-num-replicas=1 --max-num-replicas=10 --target-cpu-utilization=0.6 --cool-down-period=60 > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

echo -n "Setting named ports for instance group... "
gcloud compute instance-groups set-named-ports lb-backend-example \
--named-ports http:80 \
--zone $ZONE > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

# Create health check
echo -n "Creating health check... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "http-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/healthChecks" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create security policy
echo -n "Creating security policy... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "description": "Default security policy for: http-backend",
    "name": "default-security-policy-for-backend-service-http-backend",
    "rules": [
      {
        "action": "allow",
        "match": {
          "config": {
            "srcIpRanges": [
              "*"
            ]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "priority": 2147483647
      },
      {
        "action": "throttle",
        "description": "Default rate limiting rule",
        "match": {
          "config": {
            "srcIpRanges": [
              "*"
            ]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "priority": 2147483646,
        "rateLimitOptions": {
          "conformAction": "allow",
          "enforceOnKey": "IP",
          "exceedAction": "deny(403)",
          "rateLimitThreshold": {
            "count": 500,
            "intervalSec": 60
          }
        }
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create backend service
echo -n "Creating backend service... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "backends": [
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE"'/instanceGroups/lb-backend-example",
        "maxUtilization": 0.8
      }
    ],
    "cdnPolicy": {
      "cacheKeyPolicy": {
        "includeHost": true,
        "includeProtocol": true,
        "includeQueryString": true
      },
      "cacheMode": "USE_ORIGIN_HEADERS",
      "negativeCaching": false,
      "serveWhileStale": 0
    },
    "compressionMode": "DISABLED",
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "enableCDN": true,
    "healthChecks": [
      "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"
    ],
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "logConfig": {
      "enable": true,
      "sampleRate": 1
    },
    "name": "http-backend",
    "portName": "http",
    "protocol": "HTTP",
    "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/backendServices" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Set security policy for backend service
echo -n "Setting security policy for backend service... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create URL map
echo -n "Creating URL map... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
    "name": "http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create target HTTP proxy
echo -n "Creating target HTTP proxy... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create forwarding rule
echo -n "Creating forwarding rule... "
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

sleep 10

# Create reCAPTCHA keys
echo -n "Creating reCAPTCHA session token key... "
TOKEN_KEY=$(gcloud recaptcha keys create --display-name=test-key-name \
  --web --allow-all-domains --integration-type=score --testing-score=0.5 \
  --waf-feature=session-token --waf-service=ca --format="value(name)" 2>/dev/null) &
spinner
TOKEN_KEY=$(echo "$TOKEN_KEY" | awk -F '/' '{print $NF}')
echo "Done (Key: $TOKEN_KEY)"
echo ""

echo -n "Creating reCAPTCHA challenge page key... "
RECAPTCHA_KEY=$(gcloud recaptcha keys create --display-name=challenge-page-key \
--web --allow-all-domains --integration-type=INVISIBLE \
--waf-feature=challenge-page --waf-service=ca --format="value(name)" 2>/dev/null) &
spinner
RECAPTCHA_KEY=$(echo "$RECAPTCHA_KEY" | awk -F '/' '{print $NF}')
echo "Done (Key: $RECAPTCHA_KEY)"
echo ""

# Get instance name
echo -n "Getting instance name... "
INSTANCE_NAME=$(gcloud compute instances list --format="value(name)" \
  --filter="name~^lb-backend-example" | head -n 1 2>/dev/null) &
spinner
echo "Done (Instance: $INSTANCE_NAME)"
echo ""

# Prepare disk with custom content
echo -n "Preparing disk with custom content... "
cat > prepare_disk.sh <<'EOF_END'
export TOKEN_KEY="$TOKEN_KEY"

cd /var/www/html/

sudo tee index.html > /dev/null <<HTML_CONTENT
<!doctype html>
<html>
<head>
  <title>ReCAPTCHA Session Token</title>
  <script src="https://www.google.com/recaptcha/enterprise.js?render=$TOKEN_KEY&waf=session" async defer></script>
</head>
<body>
  <h1>Main Page</h1>
  <p><a href="/good-score.html">Visit allowed link</a></p>
  <p><a href="/bad-score.html">Visit blocked link</a></p>
  <p><a href="/median-score.html">Visit redirect link</a></p>
</body>
</html>
HTML_CONTENT

sudo tee good-score.html > /dev/null <<GOOD_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>Congrats! You have a good score!!</h1>
</body>
</html>
GOOD_SCORE_CONTENT

sudo tee bad-score.html > /dev/null <<BAD_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>Sorry, You have a bad score!</h1>
</body>
</html>
BAD_SCORE_CONTENT

sudo tee median-score.html > /dev/null <<MEDIAN_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>You have a median score that we need a second verification.</h1>
</body>
</html>
MEDIAN_SCORE_CONTENT
EOF_END

gcloud compute scp prepare_disk.sh $INSTANCE_NAME:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet > /dev/null 2>&1 &
gcloud compute ssh $INSTANCE_NAME --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="export TOKEN_KEY=$TOKEN_KEY && bash /tmp/prepare_disk.sh" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

# Create reCAPTCHA security policy
echo -n "Creating reCAPTCHA security policy... "
gcloud compute security-policies create recaptcha-policy \
    --description "policy for bot management" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

echo -n "Updating security policy with reCAPTCHA key... "
gcloud compute security-policies update recaptcha-policy \
  --recaptcha-redirect-site-key "$RECAPTCHA_KEY" > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

echo -n "Adding security policy rules... "
gcloud compute security-policies rules create 2000 \
    --security-policy recaptcha-policy \
    --expression "request.path.matches('good-score.html') && token.recaptcha_session.score > 0.4" \
    --action allow > /dev/null 2>&1 &

gcloud compute security-policies rules create 3000 \
    --security-policy recaptcha-policy \
    --expression "request.path.matches('bad-score.html') && token.recaptcha_session.score < 0.6" \
    --action "deny-403" > /dev/null 2>&1 &

gcloud compute security-policies rules create 1000 \
    --security-policy recaptcha-policy \
    --expression "request.path.matches('median-score.html') && token.recaptcha_session.score == 0.5" \
    --action redirect \
    --redirect-type google-recaptcha > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

echo -n "Updating backend service with security policy... "
gcloud compute backend-services update http-backend \
    --security-policy recaptcha-policy --global > /dev/null 2>&1 &
spinner
echo "Done"
echo ""

# Get load balancer IP
echo -n "Getting load balancer IP address... "
LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)" 2>/dev/null) &
spinner
echo "Done"
echo ""

# Final output
echo "============================================="
echo " Setup Complete!                            "
echo "============================================="
echo " Load Balancer IP: http://$LB_IP_ADDRESS"
echo " Test URLs:"
echo "   - Main page: http://$LB_IP_ADDRESS/index.html"
echo "   - Good score test: http://$LB_IP_ADDRESS/good-score.html"
echo "   - Bad score test: http://$LB_IP_ADDRESS/bad-score.html"
echo "   - Median score test: http://$LB_IP_ADDRESS/median-score.html"
echo ""
echo " Thank you for following along with Dr. Abhishek's"
echo " Cloud Tutorial! Don't forget to like the video"
echo " and subscribe to the channel for more content!"
echo "============================================="
