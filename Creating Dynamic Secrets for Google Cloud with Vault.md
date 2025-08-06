## Creating Dynamic Secrets for Google Cloud with Vault





### ⚠️ **Disclaimer**  

<div style="background-color: #fff3cd; padding: 15px; border-left: 5px solid #ffc107; border-radius: 4px; margin: 20px 0;">

📌 **Important Notice**  

This educational material is provided **for learning purposes only** to help you:  
- Understand Google Cloud lab services  
- Enhance your technical skills  
- Advance your cloud computing career  

**Before using any scripts or guides:**  
1. Always review the content thoroughly  
2. Complete labs through official channels first  
3. Comply with [Qwiklabs Terms of Service](https://www.qwiklabs.com/terms_of_service)  
4. Adhere to [YouTube Community Guidelines](https://www.youtube.com/howyoutubeworks/policies/community-guidelines/)  

❌ **Not intended** to bypass legitimate learning processes  
✅ **Meant to supplement** your educational journey  

</div>



### © **Credit & Attribution**  

<div style="background-color: #e7f5ff; padding: 15px; border-left: 5px solid #4dabf7; border-radius: 4px; margin: 20px 0;">

**Original Content Rights:**  
All rights and credit for the original lab content belong to:  
🔹 [Google Cloud Skill Boost](https://www.cloudskillsboost.google/)  
🔹 Google LLC  

**Copyright Notice:**  
- DM for credit/removal requests  
- No copyright infringement intended  
- Educational fair use purpose only  

🙏 **Acknowledgement:**  
We gratefully acknowledge Google's learning resources that make cloud education accessible  

</div>

```



gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

#!/bin/bash

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get install vault

vault


cat > config.hcl <<EOF_CP
storage "raft" {
  path    = "./vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = "true"
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true
EOF_CP


mkdir -p ./vault/data

nohup vault server -config=config.hcl > vault_server.log 2>&1 &

sleep 10

export VAULT_ADDR='http://127.0.0.1:8200'

vault operator init -key-shares=5 -key-threshold=3 > vault_init_output.txt

KEY_1=$(grep 'Unseal Key 1:' vault_init_output.txt | awk '{print $NF}')
KEY_2=$(grep 'Unseal Key 2:' vault_init_output.txt | awk '{print $NF}')
KEY_3=$(grep 'Unseal Key 3:' vault_init_output.txt | awk '{print $NF}')
TOKEN=$(grep 'Initial Root Token:' vault_init_output.txt | awk '{print $NF}')

vault operator unseal $KEY_1
vault operator unseal $KEY_2
vault operator unseal $KEY_3

vault login $TOKEN

sleep 10

vault secrets enable gcp


SERVICE_ACCOUNT_EMAIL="$DEVSHELL_PROJECT_ID@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

gcloud iam service-accounts keys create ~/$DEVSHELL_PROJECT_ID.json \
  --iam-account $SERVICE_ACCOUNT_EMAIL

gcloud iam service-accounts keys list --iam-account $SERVICE_ACCOUNT_EMAIL


export VAULT_ADDR='http://127.0.0.1:8200'


vault write gcp/config \
credentials=@/home/$USER/$DEVSHELL_PROJECT_ID.json \
ttl=3600 \
max_ttl=86400


cat > bindings.hcl <<EOF_CP
resource "buckets/$DEVSHELL_PROJECT_ID" {
  roles = [
    "roles/storage.objectAdmin",
    "roles/storage.legacyBucketReader",
  ]
}
EOF_CP


vault write gcp/roleset/my-token-roleset \
    project="$DEVSHELL_PROJECT_ID" \
    secret_type="access_token"  \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl


TOKEN=$(vault read -field=token gcp/roleset/my-token-roleset/token)


curl "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID" \
  --header "Authorization: Bearer $TOKEN" \
  --header "Accept: application/json"


curl -X GET \
  -H "Authorization: Bearer $TOKEN" \
  -o "sample.txt" \
  "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID/o/sample.txt?alt=media"


vault write gcp/roleset/my-key-roleset \
    project="$DEVSHELL_PROJECT_ID" \
    secret_type="service_account_key"  \
    bindings=@bindings.hcl

vault read gcp/roleset/my-key-roleset/key


vault write gcp/static-account/my-token-account \
    service_account_email="$SERVICE_ACCOUNT_EMAIL" \
    secret_type="access_token"  \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl

vault write gcp/static-account/my-key-account \
    service_account_email="$SERVICE_ACCOUNT_EMAIL" \
    secret_type="service_account_key"  \
    bindings=@bindings.hcl

export VAULT_ADDR='http://127.0.0.1:8200'


vault write gcp/config \
credentials=@/home/$USER/$DEVSHELL_PROJECT_ID.json \
ttl=3600 \
max_ttl=86400


cat > bindings.hcl <<EOF_CP
resource "buckets/$DEVSHELL_PROJECT_ID" {
  roles = [
    "roles/storage.objectAdmin",
    "roles/storage.legacyBucketReader",
  ]
}
EOF_CP


vault write gcp/roleset/my-token-roleset \
    project="$DEVSHELL_PROJECT_ID" \
    secret_type="access_token"  \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl


    

```



<div align="center">

<h3>🌟 Connect with fellow cloud enthusiasts, ask questions, and share your learning journey! 🌟</h3>

<div align="center">

<h3 style="font-family: 'Segoe UI', sans-serif; color: linear-gradient(90deg, #4F46E5, #E114E5);">🌟 Connect with Cloud Enthusiasts 🌟</h3>
<p style="font-family: 'Segoe UI', sans-serif;">Join the community, share knowledge, and grow together!</p>

<!-- Telegram Channel -->
<a href="https://t.me/+gBcgRTlZLyM4OGI1" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Join_Telegram_Channel-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white&labelColor=2CA5E0&color=white&gradient=linear-gradient(90deg, #2CA5E0, #2488C8)" alt="Telegram Channel"/>
</a>

<!-- Telegram Group -->
<a href="https://t.me/+RujS6mqBFawzZDFl" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Join_Telegram_Group-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white&labelColor=2CA5E0&color=white&gradient=linear-gradient(90deg, #2CA5E0, #2488C8)" alt="Telegram Group"/>
</a>

<!-- YouTube -->
<a href="https://www.youtube.com/@drabhishek.5460?sub_confirmation=1" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Subscribe_YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white&labelColor=FF0000&color=white&gradient=linear-gradient(90deg, #FF0000, #CC0000)" alt="YouTube"/>
</a>

<!-- Instagram -->
<a href="https://www.instagram.com/drabhishek.5460/" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Follow_Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white&labelColor=E4405F&color=white&gradient=linear-gradient(90deg, #E4405F, #C13584)" alt="Instagram"/>
</a>

<!-- X (Twitter) -->
<a href="https://x.com/DAbhishek5460" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Follow_X-000000?style=for-the-badge&logo=x&logoColor=white&labelColor=000000&color=white&gradient=linear-gradient(90deg, #000000, #2D2D2D)" alt="X (Twitter)"/>
</a>

</div>
