
## Develop Solutions using Model Garden models and APIs: Challenge Lab
## Do Like the Video And Subscribe The Channel 
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

📌 Claude.py
``````


import os
from logs import write_log_entry
from anthropic import AnthropicVertex

project_id = os.environ['GOOGLE_CLOUD_PROJECT']
region = os.environ['GOOGLE_CLOUD_CLAUDE_REGION']

client = AnthropicVertex(region=region, project_id=project_id)

def get_claude_response(models, prompt, output_area):
    """Streams response from Claude model using Anthropic SDK."""
    response = ""
    system_msg = (
        "You are a knowledgeable assistant for Cymbal Shop. "
        "Be conversational but friendly. Don't recommend competing products."
    )
    messages = [{"role": "user", "content": prompt}]
    
    with client.messages.stream(
        model=models['Claude'],
        system=system_msg,
        messages=messages,
        max_tokens=2048
    ) as stream:
        for chunk in stream.text_stream:
            write_log_entry(models['Claude'], prompt, chunk)
            response += chunk
            output_area.markdown(response, unsafe_allow_html=True)
    
    return response

``````

📌 llama.py
`````
import streamlit as st
import os
from logs import write_log_entry

import openai
from google.auth import default, transport

project_id = os.environ['GOOGLE_CLOUD_PROJECT']
region = os.environ['GOOGLE_CLOUD_REGION']

def get_llama_response(models, prompt, output_area):
    """Streams response from Llama model using OpenAI-compatible SDK."""

    # Set up Google Cloud credentials and refresh token
    credentials, _ = default()
    auth_request = transport.requests.Request()
    credentials.refresh(auth_request)

    # Construct base URL for Vertex AI OpenAI-compatible endpoint
    client = openai.OpenAI(
        base_url=f"https://{region}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{region}/endpoints/openapi/chat/completions?",
        api_key=credentials.token,
    )

    system_msg = {
        "role": "system",
        "content": (
            "You are the Cymbal Generative AI Chatbot. You provide clear, accurate, "
            "and professional responses. Use step-by-step reasoning if prompted."
        )
    }
    welcome_msg = {"role": "assistant", "content": "Hi! I'm the Cymbal Chatbot. How can I help you?"}
    user_msg = {"role": "user", "content": prompt}
    messages = [system_msg, welcome_msg, user_msg]

    # Pass all necessary parameters for streaming chat completion
    stream = client.chat.completions.create(
    model=models['Llama'],
    messages=messages,
    stream=True,            # Optional, only if you want streaming
    temperature=0.2,
    max_tokens=1024
)


    response = ""
    for chunk in stream:
        content = chunk.choices[0].delta.content
        if content:
            write_log_entry(models['Llama'], prompt, content)
            response += content
            output_area.markdown(response, unsafe_allow_html=True)

`````
📌 model_garden_challenge_notebook.ipynb
````
from google.cloud import aiplatform
import logging

prompt = "Write a function to list n Fibonacci numbers in Python."

endpoint = aiplatform.Endpoint(
    endpoint_name="projects/1096797455311/locations/us-central1/endpoints/5062324157606264832"
)

instances = [
    {"prompt": prompt}
]

parameters = {
    "temperature": 1.0,
    "maxOutputTokens": 500,
    "topP": 1.0,
    "topK": 1,
}

# Make prediction call
response = endpoint.predict(instances=instances, parameters=parameters)

# Print response
for prediction in response.predictions:
    print(prediction.split("<|file_separator|>")[0])

print("Deployed model ID:", response.deployed_model_id)

# Logging
logging.info(f"Fibonacci function: {response}")

````
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
