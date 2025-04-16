import os
import logging
import streamlit as st
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
from tenacity import retry, stop_after_attempt, wait_exponential

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Attach Cloud Logging handler
try:
    log_client = cloud_logging.Client()
    log_client.setup_logging()
except Exception as e:
    logger.warning(f"Cloud logging setup failed: {e}")

# Initialize Vertex AI
PROJECT_ID = os.environ.get("GCP_PROJECT", "your-default-project")
LOCATION = os.environ.get("GCP_REGION", "us-central1")

if not PROJECT_ID or not LOCATION:
    st.error("❌ GCP Project configuration missing. Please set GCP_PROJECT and GCP_REGION environment variables.")
    st.stop()

try:
    vertexai.init(project=PROJECT_ID, location=LOCATION)
except Exception as e:
    logger.error(f"Vertex AI initialization failed: {e}")
    st.error("Failed to initialize Vertex AI. Please check your project settings.")
    st.stop()

@st.cache_resource(ttl=3600)
def load_models():
    try:
        model = GenerativeModel("gemini-pro")
        # Test with a simple prompt to verify it works
        test_response = model.generate_content("Hello")
        if not test_response.text:
            raise ValueError("Model test failed")
        return model
    except Exception as e:
        st.error(f"Model initialization failed: {str(e)}")
        st.stop()

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def get_gemini_pro_text_response(
    model: GenerativeModel,
    contents: str,
    generation_config: GenerationConfig,
):
    safety_settings = [
        SafetySetting(category=HarmCategory.HARM_CATEGORY_HARASSMENT, threshold=HarmBlockThreshold.BLOCK_ONLY_HIGH),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold=HarmBlockThreshold.BLOCK_ONLY_HIGH),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold=HarmBlockThreshold.BLOCK_ONLY_HIGH),
        SafetySetting(category=HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold=HarmBlockThreshold.BLOCK_ONLY_HIGH),
    ]

    try:
        response = model.generate_content(
            [Part.from_text(contents)],
            generation_config=generation_config,
            safety_settings=safety_settings,
            stream=False,
        )
        
        if response.candidates and response.candidates[0].content.parts:
            return response.candidates[0].content.parts[0].text
        else:
            logger.error(f"Empty response received: {response}")
            return "The recipe generation returned an empty response. Please try again with different inputs."
            
    except Exception as e:
        logger.error(f"API Error: {str(e)}")
        raise  # Re-raise for tenacity to handle retries

# Streamlit UI
st.set_page_config(page_title="AI Chef", page_icon="👨🍳")
st.header("👨🍳 AI Chef", divider="rainbow")
st.caption("Powered by Google Gemini AI")

text_model_pro = load_models()

# User Input Section
with st.form("recipe_inputs"):
    col1, col2 = st.columns(2)
    
    with col1:
        cuisine = st.selectbox(
            "What cuisine do you desire?",
            ("American", "Chinese", "French", "Indian", "Italian", "Japanese", "Mexican", "Turkish"),
            index=None,
            placeholder="Select cuisine...",
            key="cuisine"
        )
        
        ingredient_1 = st.text_input("Main Ingredient 1", value="", key="ingredient_1")
        ingredient_2 = st.text_input("Main Ingredient 2", value="", key="ingredient_2")
        ingredient_3 = st.text_input("Main Ingredient 3", value="", key="ingredient_3")
    
    with col2:
        dietary_preference = st.selectbox(
            "Dietary Preference",
            ("None", "Diabetes", "Gluten free", "Halal", "Keto", "Kosher", 
             "Lactose Intolerance", "Paleo", "Vegan", "Vegetarian"),
            index=None,
            placeholder="Select preference...",
            key="dietary_preference"
        )
        
        allergy = st.text_input("Allergies to exclude", value="", placeholder="e.g., peanuts, shellfish", key="allergy")
        wine = st.radio("Wine Pairing", ["None", "Red", "White", "Rosé"], key="wine", horizontal=True)
    
    generate_btn = st.form_submit_button("Generate Recipes", type="primary")

if generate_btn:
    # Validate inputs
    validation_errors = []
    if not cuisine:
        validation_errors.append("Please select a cuisine")
    if not dietary_preference:
        validation_errors.append("Please select a dietary preference")
    if not (ingredient_1 and ingredient_2 and ingredient_3):
        validation_errors.append("Please provide at least three main ingredients")
    
    if validation_errors:
        for error in validation_errors:
            st.error(error)
    else:
        prompt = f"""Create 3 detailed {cuisine} recipes that:
        - Are {dietary_preference if dietary_preference != 'None' else ''} friendly
        - Exclude {allergy if allergy else 'no specific allergens'}
        - Primarily use {ingredient_1}, {ingredient_2}, and {ingredient_3}
        - Include {wine if wine != 'None' else 'no'} wine pairing
        
        For each recipe provide:
        1. Creative name
        2. Ingredients list (quantities included)
        3. Clear step-by-step instructions
        4. Preparation and cooking time
        5. {f"{wine} wine pairing suggestion" if wine != 'None' else ""}
        6. Nutritional information (calories, macros)
        7. Serving suggestions
        
        Make the recipes practical for home cooking with clear measurements.
        """
        
        config = GenerationConfig(
            temperature=0.7,
            top_p=0.9,
            top_k=40,
            max_output_tokens=2500
        )

        with st.spinner("🧑🍳 Chef is preparing your recipes..."):
            try:
                response = get_gemini_pro_text_response(
                    text_model_pro,
                    prompt,
                    generation_config=config,
                )
                
                if response and not response.startswith("Failed"):
                    st.success("✅ Recipes generated successfully!")
                    st.markdown("---")
                    
                    # Display with nice formatting
                    st.subheader(f"🍽️ {cuisine} Recipes ({dietary_preference})")
                    st.markdown(response)
                    
                    # Add download button
                    st.download_button(
                        label="📥 Download Recipes",
                        data=response,
                        file_name=f"{cuisine}_{dietary_preference}_recipes.txt",
                        mime="text/plain"
                    )
                else:
                    st.warning(response)
                    
            except Exception as e:
                logger.exception("Generation failed after retries")
                st.error(f"😞 Recipe generation failed after multiple attempts. Error: {str(e)}")
                st.info("Please try again with slightly different inputs or come back later")

# Footer
st.markdown("---")
st.caption("""
    *Note: Recipe quality may vary based on input ingredients. 
    Always check for allergens before cooking.*
""")
