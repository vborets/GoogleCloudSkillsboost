import os
import streamlit as st
import logging
from google.cloud import logging as cloud_logging
import vertexai
from vertexai.preview.generative_models import (
    GenerationConfig,
    GenerativeModel,
    HarmBlockThreshold,
    HarmCategory,
    Part,
    SafetySetting,
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.propagate = False

# Attach Cloud Logging handler
log_client = cloud_logging.Client()
log_client.setup_logging()

# Initialize Vertex AI
PROJECT_ID = os.environ.get("GCP_PROJECT")
LOCATION = os.environ.get("GCP_REGION")
vertexai.init(project=PROJECT_ID, location=LOCATION)

@st.cache_resource
def load_models():
    return GenerativeModel("gemini-pro")

def get_gemini_pro_text_response(
    model: GenerativeModel,
    contents: str,
    generation_config: GenerationConfig,
):
    safety_settings = [
        SafetySetting(category=HarmCategory.HARM_CATEGORY_HARASSMENT, threshold=HarmBlockThreshold.BLOCK_NONE),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold=HarmBlockThreshold.BLOCK_NONE),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold=HarmBlockThreshold.BLOCK_NONE),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold=HarmBlockThreshold.BLOCK_NONE),
    ]

    response = model.generate_content(
        [Part.from_text(contents)],
        generation_config=generation_config,
        safety_settings=safety_settings,
        stream=False,  # non-streaming mode
    )

    try:
        return response.text
    except AttributeError as e:
        logger.error(f"Missing text in response: {e}")
        return "No response generated."

# Streamlit layout
st.header("Vertex AI Gemini API", divider="gray")
text_model_pro = load_models()

st.write("Using Gemini Pro - Text only model")
st.subheader("AI Chef")

cuisine = st.selectbox(
    "What cuisine do you desire?",
    ("American", "Chinese", "French", "Indian", "Italian", "Japanese", "Mexican", "Turkish"),
    index=None,
    placeholder="Select your desired cuisine."
)

dietary_preference = st.selectbox(
    "Do you have any dietary preferences?",
    ("Diabetes", "Gluten free", "Halal", "Keto", "Kosher", "Lactose Intolerance", "Paleo", "Vegan", "Vegetarian", "None"),
    index=None,
    placeholder="Select your dietary preference."
)

allergy = st.text_input("Enter your food allergy:", key="allergy", value="peanuts")
ingredient_1 = st.text_input("Enter your first ingredient:", key="ingredient_1", value="ahi tuna")
ingredient_2 = st.text_input("Enter your second ingredient:", key="ingredient_2", value="chicken breast")
ingredient_3 = st.text_input("Enter your third ingredient:", key="ingredient_3", value="tofu")
wine = st.radio("What wine do you prefer?", ["Red", "White", "None"], key="wine", horizontal=True)

generate_t2t = st.button("Generate my recipes.", key="generate_t2t")
if generate_t2t:
    if not cuisine or not dietary_preference:
        st.error("Please select both a cuisine and a dietary preference.")
    else:
        prompt = f"""
        I am a Chef. I need to create {cuisine} recipes for customers who want {dietary_preference} meals.
        However, don't include recipes that use ingredients with the customer's {allergy} allergy.
        I have {ingredient_1}, {ingredient_2}, and {ingredient_3} in my kitchen and other ingredients.
        The customer's wine preference is {wine}.
        Please provide some meal recommendations.
        For each recommendation include:
        - recipe title
        - preparation instructions
        - time to prepare
        - wine pairing
        - calories
        - nutritional facts.
        """

        config = GenerationConfig(
            temperature=0.8,
            max_output_tokens=2048
        )

        with st.spinner("Generating your recipes using Gemini..."):
            first_tab1, first_tab2 = st.tabs(["Recipes", "Prompt"])
            with first_tab1:
                try:
                    response = get_gemini_pro_text_response(
                        text_model_pro,
                        prompt,
                        generation_config=config,
                    )
                    if response:
                        st.write("Your recipes:")
                        st.write(response)
                        logger.info(response)
                except Exception as e:
                    logger.error(f"Error while generating recipes: {e}")
                    st.error("Failed to generate recipes. Please check the logs.")
            with first_tab2:
                st.text(prompt)
