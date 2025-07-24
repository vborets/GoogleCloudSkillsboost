## Configure AI Applications to Optimize Search Results: Challenge Lab


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
#!/bin/bash

# Prompt for Project ID
read -p "Enter your Google Cloud Project ID: " PROJECT_ID

# Set the GCP project (optional but recommended)
gcloud config set project "$PROJECT_ID"

# Create metadata.json
cat > metadata.json <<EOF
{"id": "doc-1", "jsonData": "{\"title\":\"Heaven Resort\",\"category\":\"information\",\"rating\":4.8}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel1.pdf"}}
{"id": "doc-2", "jsonData": "{\"title\":\"Paradise Reef Resort\",\"category\":\"information\",\"rating\":4.7}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel2.pdf"}}
{"id": "doc-3", "jsonData": "{\"title\":\"AquaPulse Maldives\",\"category\":\"information\",\"rating\":4.0}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel3.pdf"}}
{"id": "doc-4", "jsonData": "{\"title\":\"Heaven Resort Financials\",\"category\":\"financials\",\"rating\":4.8}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel1-financials.pdf"}}
{"id": "doc-5", "jsonData": "{\"title\":\"Paradise Reef Resort Financials\",\"category\":\"financials\",\"rating\":4.7}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel2-financials.pdf"}}
{"id": "doc-6", "jsonData": "{\"title\":\"AquaPulse Maldives Financials\",\"category\":\"financials\",\"rating\":4.0}", "content": {"mimeType": "application/pdf", "uri": "gs://\${PROJECT_ID}/hotel3-financials.pdf"}}
EOF

# Replace placeholder with actual project ID
sed -i "s/\\\${PROJECT_ID}/$PROJECT_ID/g" metadata.json

# Upload to GCS bucket
gsutil cp metadata.json gs://${PROJECT_ID}/metadata.json

echo "metadata.json created and uploaded to gs://${PROJECT_ID}/metadata.json"

```
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="user:$(gcloud config get-value account)" \
--role="roles/discoveryengine.viewer"
```
```
# First authenticate and set your project
gcloud auth login
export PROJECT_ID=""
```
```
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
"https://discoveryengine.googleapis.com/v1alpha/projects/467352334122/locations/global/collections/default_collection/engines/cymbal-hotels_1753364142024/servingConfigs/default_search:search" \
-d '{
"query": "What hotels are available in the Maldives?",
"pageSize": 10,
"filter": "category: ANY(\"information\")",
"queryExpansionSpec": {
"condition": "AUTO"
},
"spellCorrectionSpec": {
"mode": "AUTO"
},
"relevanceScoreSpec": {
"returnRelevanceScore": true
},
"languageCode": "en-US",
"contentSearchSpec": {
"extractiveContentSpec": {
"maxExtractiveAnswerCount": 1
}
},
"facetSpecs": [
{
"facetKey": {
"key": "category"
},
"limit": 30
}
],
"naturalLanguageQueryUnderstandingSpec": {
"filterExtractionCondition": "ENABLED"
},
"userInfo": {
"timeZone": "Asia/Calcutta"
},
"session": "projects/467352334122/locations/global/collections/default_collection/engines/cymbal-hotels_1753364142024/sessions/-"
}'
```
```
# *********************************************************
#  Knowledge shared by Dr. Abhishek
#  Please LIKE, SHARE, and SUBSCRIBE: 
#  https://www.youtube.com/@drabhishek.5460/videos 
# *********************************************************
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
