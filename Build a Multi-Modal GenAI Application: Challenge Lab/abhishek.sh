#!/bin/bash

# Color Definitions
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome Message
echo "${MAGENTA_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...        ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for Region Input
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
echo

# Confirm User Input
echo "${GREEN_TEXT}${BOLD_TEXT}You have entered the region:${RESET_FORMAT} ${YELLOW_TEXT}${REGION}${RESET_FORMAT}"
echo

# Fetch GCP Project ID
ID="$(gcloud projects list --format='value(PROJECT_ID)')"

# Generate Image Python Script
cat > GenerateImage.py <<EOF_END
import argparse

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
  project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
  """Generate an image using a text prompt."""
  vertexai.init(project=project_id, location=location)
  model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
  images = model.generate_images(
    prompt=prompt,
    number_of_images=1,
    seed=1,
    add_watermark=False,
  )
  images[0].save(location=output_file)
  return images

generate_image(
  project_id='$ID',
  location='$REGION',
  output_file='image.jpeg',
  prompt='Create an image of a cricket ground in the heart of Los Angeles',
)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Generating an image... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/GenerateImage.py
echo "${GREEN_TEXT}${BOLD_TEXT}Image generated successfully! Check 'image.jpeg' in your working directory.${RESET_FORMAT}"

# Multimodal Text Generation Script
cat > genai.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part

def generate_text(project_id: str, location: str) -> str:
  vertexai.init(project=project_id, location=location)
  multimodal_model = GenerativeModel("gemini-2.0-flash-001")
  response = multimodal_model.generate_content(
    [
      Part.from_uri(
        "gs://generativeai-downloads/images/scones.jpg", mime_type="image/jpeg"
      ),
      "what is shown in this image?",
    ]
  )
  return response.text

project_id = "$ID"
location = "$REGION"

response = generate_text(project_id, location)
print(response)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Processing text with multimodal model first time... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}Text process completed, see output above.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting 30 seconds before running the process again...${RESET_FORMAT}"
sleep 30

echo "${YELLOW_TEXT}${BOLD_TEXT}Processing text with multimodal model second time... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}Text process completed, see output above.${RESET_FORMAT}"

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo


echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to Dr Abhishek's YouTube Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@drabhishek.5460/videos${RESET_FORMAT}"
echo
