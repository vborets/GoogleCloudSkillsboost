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
# Export your Project ID
export PROJECT_ID=""
```
```
# Export the base Cloud Storage path
export BASE_URI="gs://${PROJECT_ID}"

# Export all document URIs
export DOC1_URI="${BASE_URI}/hotel1.pdf"
export DOC2_URI="${BASE_URI}/hotel2.pdf"
export DOC3_URI="${BASE_URI}/hotel3.pdf"
export DOC4_URI="${BASE_URI}/hotel1-financials.pdf"
export DOC5_URI="${BASE_URI}/hotel2-financials.pdf"
export DOC6_URI="${BASE_URI}/hotel3-financials.pdf"
export METADATA_URI="${BASE_URI}/metadata.json"

# *********************************************************
#  Dr. Abhishek Official Branding - Knowledge and Integrity
#  For more insights: Like, Share, and Subscribe!
#  YouTube: https://www.youtube.com/@drabhishek.5460/videos
# *********************************************************

# -------------------------------------
# Task 1: Create and upload metadata.json
# -------------------------------------

cat > metadata.json <<EOF
{"id": "doc-1", "title": "Heaven Resort", "category": "information", "rating": 4.8, "Document URI": "${DOC1_URI}"}
{"id": "doc-2", "title": "Paradise Reef Resort", "category": "information", "rating": 4.7, "Document URI": "${DOC2_URI}"}
{"id": "doc-3", "title": "AquaPulse Maldives", "category": "information", "rating": 4.0, "Document URI": "${DOC3_URI}"}
{"id": "doc-4", "title": "Heaven Resort Financials", "category": "financials", "rating": 4.8, "Document URI": "${DOC4_URI}"}
{"id": "doc-5", "title": "Paradise Reef Resort Financials", "category": "financials", "rating": 4.7, "Document URI": "${DOC5_URI}"}
{"id": "doc-6", "title": "AquaPulse Maldives Financials", "category": "financials", "rating": 4.0, "Document URI": "${DOC6_URI}"}
EOF

gsutil cp metadata.json "${METADATA_URI}"

# ---------------------------------------------------------------
# Task 4: Filter responses (using variables)
# ---------------------------------------------------------------
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores/cymbal-travel-datastore/servingConfigs/default_search:search" \
  -d '{
    "query": "What hotels are available in the Maldives?",
    "filter": "category:information"
  }'

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores/cymbal-travel-datastore/servingConfigs/default_search:search" \
  -d '{
    "query": "What is the revenue for the hotels in the Maldives?",
    "filter": "category:financials"
  }'

# ---------------------------------------------------------------
# Task 5: Boost results with higher ratings
# ---------------------------------------------------------------
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores/cymbal-travel-datastore/servingConfigs/default_search:search" \
  -d '{
    "query": "What hotels are available in the Maldives?",
    "filter": "category:information",
    "pageSize": 2
  }'

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
