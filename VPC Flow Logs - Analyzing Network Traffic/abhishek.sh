#!/bin/bash


show_banner() {
    echo -e "\033[0;96m\033[1m"
    echo "   ____  ____    __  ___   ___  ___  ___  __  __  ____  _  _  ____ "
    echo "  (  _ \( ___)  /__\( _ ) / __)/ __)/ __)(  )(  )( ___)( \( )(_  _)"
    echo "   )   / )__)  /(__)) _ \( (__ \__ \\__ \ )(__)(  )__)  )  (   )(  "
    echo "  (_)\_)(____)(__)(____/ \___)(___/(___/(______)(____)(_)\_) (__) "
    echo -e "\033[0m"
    echo -e "\033[0;93m\033[1m          C L O U D   I N F R A S T R U C T U R E   S E T U P\033[0m"
    echo -e "\033[0;95m\033[1m             YouTube: https://www.youtube.com/@drabhishek.5460\033[0m"
    echo -e "\033[0;95m\033[1m        ⭐ Please Subscribe for more Cloud Tutorials! ⭐\033[0m"
    echo
}

# Spinner Animation
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

show_banner

# Original Script Content Starts Here
export REGION="${ZONE%-*}"

echo -e "\033[1;92m▶ Creating VPC Network...\033[0m"
gcloud compute networks create vpc-net --project=$DEVSHELL_PROJECT_ID --description="Subscribe to Dr. Abhishek's YouTube Channel" --subnet-mode=custom & spinner

echo -e "\033[1;92m▶ Creating Subnet...\033[0m"
gcloud compute networks subnets create vpc-subnet --project=$DEVSHELL_PROJECT_ID --network=vpc-net --region=$REGION --range=10.1.3.0/24 --enable-flow-logs & spinner

echo -e "\033[1;93m⏳ Waiting for resources to provision...\033[0m"
sleep 100 & spinner

echo -e "\033[1;92m▶ Configuring Firewall Rules...\033[0m"
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-http-ssh --direction=INGRESS --priority=1000 --network=vpc-net --action=ALLOW --rules=tcp:80,tcp:22 --source-ranges=0.0.0.0/0 --target-tags=http-server & spinner

echo -e "\033[1;92m▶ Launching Web Server...\033[0m"
gcloud compute instances create web-server --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --subnet=vpc-subnet --network=vpc-net --tags=http-server --image-family=debian-10 --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
        sudo apt update
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo systemctl enable apache2' \
    --labels=server=apache & spinner

echo -e "\033[1;92m▶ Adding HTTP Firewall Rule...\033[0m"
gcloud compute firewall-rules create allow-http \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --description="Allow HTTP traffic" & spinner

echo -e "\033[1;92m▶ Creating BigQuery Dataset...\033[0m"
bq mk bq_vpcflows & spinner

echo -e "\033[1;92m▶ Getting Server IP...\033[0m"
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)') & spinner
export MY_SERVER=$CP_IP

echo -e "\033[1;92m▶ Generating Test Traffic...\033[0m"
for ((i=1;i<=50;i++)); do 
    curl -s $MY_SERVER & 
    sleep 0.1
done
wait

echo
echo -e "\033[1;96m🔗 Open Firewall link\033[0m"
echo "https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-http-ssh?project=$DEVSHELL_PROJECT_ID"

echo -e "\033[1;96m🔗 Open Sink link\033[0m"
echo "https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_subnetwork%22%0Alog_name%3D%22projects%2F$DEVSHELL_PROJECT_ID%2Flogs%2Fcompute.googleapis.com%252Fvpc_flows%22;cursorTimestamp=2024-06-03T07:20:00.734122029Z;duration=PT1H?project=$DEVSHELL_PROJECT_ID"

echo
echo -e "\033[1;95m🎉 Setup Complete! Thank you for using Dr. Abhishek YT!\033[0m"
echo -e "\033[1;95m📺 Don't forget to subscribe: https://www.youtube.com/@drabhishek.5460\033[0m"
echo
