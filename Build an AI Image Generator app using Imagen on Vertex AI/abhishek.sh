#!/bin/bash

# Enhanced Color Definitions
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'
BOLD=$'\033[1m'
RESET=$'\033[0m'
UNDERLINE=$'\033[4m'

# Background Colors
BG_BLUE=$'\033[44m'
BG_GREEN=$'\033[42m'

# Clear screen for better visibility
clear

# Enhanced Welcome Banner
echo "${BLUE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BLUE}${BOLD}║                                                        ║${RESET}"
echo "${BLUE}${BOLD}║   ${WHITE}${BG_BLUE}🚀 IMAGE GENERATION WITH VERTEX AI 🎨${RESET}${BLUE}${BOLD}          ║${RESET}"
echo "${BLUE}${BOLD}║                                                        ║${RESET}"
echo "${BLUE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

# Get region input with validation
while true; do
    echo "${YELLOW}${BOLD}🌍 Enter Google Cloud Region (e.g., us-central1):${RESET}"
    read -r REGION_INPUT
    if [ -n "$REGION_INPUT" ]; then
        export REGION="$REGION_INPUT"
        echo "${GREEN}✓ ${WHITE}Region set to: ${CYAN}${BOLD}$REGION${RESET}"
        break
    else
        echo "${RED}✗ Region cannot be empty. Please try again.${RESET}"
    fi
done
echo

# Get Project ID
echo "${YELLOW}${BOLD}🔍 Retrieving Project ID...${RESET}"
ID="$(gcloud projects list --format='value(PROJECT_ID)' | head -1)"
if [ -z "$ID" ]; then
    echo "${RED}${BOLD}Error: Could not retrieve Project ID. Please ensure:"
    echo "1. You're authenticated with gcloud (run 'gcloud auth login')"
    echo "2. You have at least one project created${RESET}"
    exit 1
fi
echo "${GREEN}✓ ${WHITE}Project ID: ${CYAN}${BOLD}$ID${RESET}"
echo

# Create Python script with improved formatting
SCRIPT_PATH="/home/student/GenerateImage.py"
echo "${MAGENTA}${BOLD}📝 Creating image generation script...${RESET}"

cat > "$SCRIPT_PATH" <<EOF
#!/usr/bin/env python3
import argparse
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel
import sys

def generate_image(project_id, location, output_file, prompt):
    """Generate an image using Vertex AI's ImageGenerationModel"""
    try:
        print("${GREEN}[1/4] Initializing Vertex AI...${RESET}")
        vertexai.init(project=project_id, location=location)
        
        print("${GREEN}[2/4] Loading Imagen 3.0 model...${RESET}")
        model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
        
        print("${GREEN}[3/4] Generating image from prompt...${RESET}")
        images = model.generate_images(
            prompt=prompt,
            number_of_images=1,
            seed=1,
            add_watermark=False,
        )
        
        print("${GREEN}[4/4] Saving generated image...${RESET}")
        images[0].save(location=output_file)
        
        print("${GREEN}✓ Image successfully generated and saved as image.jpeg${RESET}")
        return images
    except Exception as e:
        print(f"${RED}✗ Error during image generation: {str(e)}${RESET}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    generate_image(
        project_id='$ID',
        location='$REGION',
        output_file='image.jpeg',
        prompt='Create an image of a cricket ground in the heart of Los Angeles'
    )
EOF

# Set proper permissions
chmod 755 "$SCRIPT_PATH"
chown student:student "$SCRIPT_PATH" 2>/dev/null || true

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "${RED}${BOLD}Error: Failed to create script at $SCRIPT_PATH${RESET}"
    exit 1
fi
echo "${GREEN}✓ Python script created successfully at:"
echo "${CYAN}${UNDERLINE}$SCRIPT_PATH${RESET}"
echo

# Execute the image generation
echo "${MAGENTA}${BOLD}🖼️  Starting image generation process...${RESET}"
echo "${BLUE}────────────────────────────────────────────────────${RESET}"
if sudo -u student /usr/bin/python3 "$SCRIPT_PATH"; then
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${GREEN}${BOLD}✓ Image generation completed successfully!${RESET}"
else
    echo "${BLUE}────────────────────────────────────────────────────${RESET}"
    echo "${RED}${BOLD}✗ Image generation failed${RESET}"
    exit 1
fi
echo

# Completion Banner
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║                                                        ║${RESET}"
echo "${GREEN}${BOLD}║   ${WHITE}${BG_GREEN}✅ IMAGE GENERATION LAB COMPLETED SUCCESSFULLY ✅${RESET}${GREEN}${BOLD}   ║${RESET}"
echo "${GREEN}${BOLD}║                                                        ║${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${WHITE}${BOLD}For more cloud AI tutorials and guides:${RESET}"
echo "${YELLOW}👉 Subscribe to Dr. Abhishek Cloud Tutorials:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@drabhishek.5460/videos${RESET}"
echo
echo "${MAGENTA}Thank you ${RESET}"
echo
