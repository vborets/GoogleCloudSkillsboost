#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_BLUE}${WHITE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${BG_CYAN}${BOLD}        🌟 Welcome to Dr. Abhishek's GCP Guide                         🌟${RESET}"
echo "${BG_BLUE}${WHITE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo "${BG_GREEN}${BOLD}Initializing Setup... Please Wait.${RESET}"

gcloud pubsub schemas create city-temp-schema \
        --type=avro \
        --definition='{                                             
            "type" : "record",                               
            "name" : "Avro",                                 
            "fields" : [                                     
            {                                                  
                "name" : "city",                             
                "type" : "string"                             
            },                                               
            {                                                  
                "name" : "temperature",                       
                "type" : "double"                             
            },                                               
            {                                                  
                "name" : "pressure",                          
                "type" : "int"                                
            },                                               
            {                                                  
                "name" : "time_position",                    
                "type" : "string"                             
            }                                                 
        ]                                                    
    }'

gcloud pubsub topics create temp-topic \
        --message-encoding=JSON \
        --schema=temperature-schema

gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com

cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloPubSub', cloudEvent => {
  const base64name = cloudEvent.data.message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});
EOF_END

cat > package.json <<'EOF_END'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF_END

deploy_function() {
gcloud functions deploy gcf-pubsub \
  --gen2 \
  --runtime=nodejs22 \
  --region=$LOCATION \
  --source=. \
  --entry-point=helloPubSub \
  --trigger-topic gcf-topic \
  --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "${GREEN}${BOLD}✅ Function deployed successfully...${RESET}"
        deploy_success=true
    else
        echo "${YELLOW}${BOLD}⚠️ Retrying in 20 seconds...${RESET}"
        sleep 20
    fi
done

echo "${BG_MAGENTA}${BOLD}🎉 Congratulations For Completing The Lab !!!${RESET}"
echo "${BG_YELLOW}${BLACK}${BOLD}📢 Don't forget to subscribe to Dr. Abhishek's YouTube Channel:${RESET}"
echo "${BLUE}${BOLD}👉 https://www.youtube.com/@drabhishek.5460/videos${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
