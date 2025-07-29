## Evaluate Gen AI Model and Agent Performance: Challenge Lab



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

````
!pip install --upgrade google-cloud-aiplatform google-cloud-logging --quiet
!pip install "google-cloud-aiplatform[evaluation]" --quiet
````
```
import pandas as pd
import logging
import google.cloud.logging
from IPython.display import display, Markdown

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig
from vertexai.evaluation import (
    MetricPromptTemplateExamples,
    EvalTask,
    PairwiseMetric,
    PointwiseMetric,
)

# Do not remove logging section
client = google.cloud.logging.Client()
client.setup_logging()

pd.set_option("display.max_colwidth", None)

```
```
PROJECT_ID = "qwiklabs-gcp-00-a45b05279191"
LOCATION = "us-central1"

import vertexai

# Initialize vertexai
vertexai.init(project=PROJECT_ID, location=LOCATION)

# Do not remove logging section
log_message = f"Vertex AI initialize: {vertexai}"
logging.info(log_message)

```
```
prompt_template="# System_prompt\n{system_prompt} # Question\n{question} # Description {description}"

```
```
system_prompt=["You are an retail domestic merchandise expert"]

question=["Provide a one sentence summary of the following text"]

description=[
  "Men’s Blue Dress Shorts Elevate your warm-weather wardrobe with these tailored men's blue dress shorts — where polished style meets everyday comfort. Designed ...",
  "Summer Floral Dress. Breathe life into your summer wardrobe with this effortlessly elegant floral midi dress. Crafted from lightweight, breathable fabric, ...",
  "Outdoor Garden Furniture Transform your backyard into a personal oasis with this elegant garden furniture set designed for comfort, durability, and timeless style. ...",
  "OLED 4K Ultra HD Smart TV. Step into the future of home entertainment with breathtaking clarity, vibrant color, and cinematic sound. ...",
  "Smartwash Dishwasher. Let your kitchen work for you. Say goodbye to scrubbing and soaking — the SmartWash Dishwasher delivers a powerful, whisper-quiet clean that saves you time, energy, and water. ..."
]

```
```
flash_model = GenerativeModel(
    model_name="gemini-2.0-flash",
    generation_config=GenerationConfig(temperature=0),
)


llm_response = flash_model.generate_content(
    prompt_template.format(
        system_prompt=system_prompt[0],
        question=question[0],
        description=description[1]
    )
)
display(Markdown(llm_response.text))

# Do not remove logging section
log_message = f"Markdown output: {llm_response.text}"
logging.info(log_message)

````
```
import pandas as pd

dataset=pd.DataFrame(
    {
        "system_prompt": system_prompt*5,
        "question": question*5,
        "description": description
    }
)

````
```
import pandas as pd
import datetime
from vertexai.evaluation import (
    MetricPromptTemplateExamples,
    PointwiseMetric,
    EvalTask
)
from vertexai.generative_models import GenerativeModel

# 1. Prepare the evaluation dataset
dataset = pd.DataFrame({
    "system_prompt": [
        "You are a helpful assistant that summarizes product reviews.",
        "You are an expert summarizer for customer feedback."
    ],
    "question": [
        "Summarize the following product review: 'Great camera but battery drains quickly.'",
        "Summarize this customer comment: 'Loved the speed, disliked the interface.'"
    ],
    "description": [
        "The summary should be concise and cover the main positive and negative points.",
        "Generate a short, clear summary for internal team review."
    ]
})

# 2. Set up the metric
POINTWISE_METRIC = PointwiseMetric(
    metric="summarization_quality",
    metric_prompt_template=MetricPromptTemplateExamples.Pointwise.SUMMARIZATION_QUALITY
)

# 3. Create the EvalTask
pointwise_eval_task = EvalTask(
    dataset=dataset,
    metrics=[POINTWISE_METRIC],
    experiment="product-summarization-quality"
)

# 4. Evaluate the Gemini 2.0 Flash model
model = GenerativeModel(model_name="gemini-2.0-flash")
run_ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
pointwise_result = pointwise_eval_task.evaluate(
    model=model,
    prompt_template="# System_prompt\n{system_prompt} # Question\n{question} # Description {description}",
    experiment_run_name=f"prod-sumq-{run_ts}"
)

# 5. Show results
print("Summary metrics:")
print(pointwise_result.summary_metrics)
print("\nFull metrics table:")
print(pointwise_result.metrics_table)

```
```
flash_lite_model = GenerativeModel(
    model_name="gemini-2.0-flash-lite",
    generation_config=GenerationConfig(temperature=0),
)
```

```
import pandas as pd
import datetime
from vertexai.evaluation import (
    MetricPromptTemplateExamples,
    PairwiseMetric,
    EvalTask,
)
from vertexai.generative_models import GenerativeModel

dataset = pd.DataFrame({
    "system_prompt": [
        "You are a helpful assistant that summarizes product reviews.",
        "You are an expert summarizer for customer feedback.",
    ],
    "question": [
        "Summarize the following product review: 'Great camera but battery drains quickly.'",
        "Summarize this customer comment: 'Loved the speed, disliked the interface.'"
    ],
    "description": [
        "The summary should be concise and cover the main positive and negative points.",
        "Generate a short, clear summary for internal team review."
    ]
})

candidate_model = GenerativeModel(model_name="gemini-2.0-flash")
baseline_model = GenerativeModel(model_name="gemini-2.0-flash-lite")

PAIRWISE_METRIC = PairwiseMetric(
    metric="summarization_quality",
    metric_prompt_template=MetricPromptTemplateExamples.Pairwise.SUMMARIZATION_QUALITY,
    baseline_model=baseline_model,
)

pairwise_eval_task = EvalTask(
    dataset=dataset,
    metrics=[PAIRWISE_METRIC],
    experiment="pairwise-product-summarization-quality"
)

run_ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
pairwise_result = pairwise_eval_task.evaluate(
    model=candidate_model,
    prompt_template="# System_prompt\n{system_prompt} # Question\n{question} # Description {description}",
    experiment_run_name=f"pairwise-prod-sumq-{run_ts}"
)

print("Summary metrics:")
print(pairwise_result.summary_metrics)

print("\nFull metrics table:")
print(pairwise_result.metrics_table)

# Identify and print the preferred response column
preferred_col = None
for c in ["preferred_response", "winner", "chosen_model"]:
    if c in pairwise_result.metrics_table.columns:
        preferred_col = c
        break
if preferred_col:
    print(f"\nPreferred response column ('{preferred_col}'):")
    print(pairwise_result.metrics_table[preferred_col])
else:
    print("\nPreferred response column not found.")

# Identify and print the explanation column
reason_col = None
for c in ["explanation", "rationale", "choice_reason"]:
    if c in pairwise_result.metrics_table.columns:
        reason_col = c
        break
if reason_col:
    print(f"\nModel explanations ('{reason_col}'):")
    print(pairwise_result.metrics_table[reason_col])
else:
    print("\nExplanation column not found.")
```
# Part 2 model 
```
%pip install --quiet --upgrade pip==23.3.1

%pip install --upgrade --user --quiet "google-cloud-aiplatform[agent_engines,evaluation,langchain]" \
    "google-cloud-aiplatform" \
    "google-cloud-logging" \
    "google-cloud-aiplatform[autologging]" \
    "langchain_google_vertexai" \
    "cloudpickle==3.0.0" \
    "pydantic>=2.10" \
    "requests==2.32.3"
```
```
# General
import random
import string
import google.cloud.logging
import logging

from IPython.display import HTML, Markdown, display
import pandas as pd

# Build agent
import vertexai
from google.cloud import aiplatform
from vertexai import agent_engines

# Evaluate agent
from vertexai.preview.evaluation import EvalTask
from vertexai.preview.evaluation.metrics import (
    PointwiseMetric,
    PointwiseMetricPromptTemplate,
    TrajectorySingleToolUse,
)
from vertexai.preview.reasoning_engines import LangchainAgent

# Do not remove logging section
client = google.cloud.logging.Client()
client.setup_logging()

```
```
# Variable initialization
PROJECT_ID = "qwiklabs-gcp-00-a45b05279191" 
LOCATION = "us-central1"
BUCKET_URI = "gs://qwiklabs-gcp-00-a45b05279191-experiments-staging-bucket"
EXPERIMENT_NAME = "evaluate-agent"

import vertexai

# Initialize vertexai
vertexai.init(
    project=PROJECT_ID,
    location=LOCATION,
    staging_bucket=BUCKET_URI,
    experiment=EXPERIMENT_NAME,
)
```
```
def get_product_details(product_name: str):
    """Gathers basic details about a product."""
    details = {
        "mens blue shorts": "Elevate your summer style with these tailored blue dress shorts. Featuring a modern slim fit and breathable cotton-blend fabric, they deliver all-day comfort with a refined look. Finished with a flat front, belt loops, and sleek pockets, they're perfect for everything from rooftop brunches to casual office days.",
        "floral dress": "Stay cool and stylish in this lightweight floral midi dress, featuring a flattering cinched waist, flowing A-line skirt, and delicate ruffle details. Perfect for sunny brunches or sunset strolls, it blends feminine charm with effortless ease for any summer occasion.",
        "garden furniture": "Create your perfect outdoor retreat with this stylish, weather-resistant garden furniture set featuring plush cushions, timeless design, and all-day comfort — ideal for relaxing, entertaining, or enjoying the outdoors in style.",
        "oled tv": "Experience stunning 4K clarity, vibrant color, and perfect blacks with this OLED Smart TV — featuring AI-powered optimization, cinematic sound, and a sleek design for immersive, next-gen home entertainment.",
        "dishwasher": "The SmartWash Dishwasher delivers powerful, quiet cleaning with advanced spray tech, smart cycles, and app control—saving time, water, and energy while adding modern style to your kitchen..",
    }
    return details.get(product_name, "Product details not found.")

def get_product_price(product_name: str):
    """Gathers price about a product."""
    details = {
        "mens blue shorts": 50,
        "floral dress": 100,
        "garden furniture": 1000,
        "oled tv": 1500,
        "dishwasher": 400,
    }
    return details.get(product_name, "Product price not found.")
````
````
model_name = "gemini-2.0-flash"

local_1p_agent = LangchainAgent(
    model=model_name,
    tools=[get_product_details, get_product_price],
    agent_executor_kwargs={"return_intermediate_steps": True},
)
```
```
response = local_1p_agent.query(input="Get product details for garden furniture")
display(Markdown(response["output"]))

```
response = local_1p_agent.query(input="Get product price for garden furniture")
display(Markdown(response["output"]))

```
remote_1p_agent = agent_engines.create(
    local_1p_agent,
    requirements=[
        "google-cloud-aiplatform[agent_engines,langchain]",
        "langchain_google_vertexai",
        "cloudpickle==3.0.0",
        "pydantic>=2.10",
        "requests==2.32.3",
    ],
)

```
response = remote_1p_agent.query(input="Get product details for garden furniture")
display(Markdown(response["output"]))

response = remote_1p_agent.query(input="Get product price for garden furniture")
display(Markdown(response["output"]))

```
eval_data = {
    "prompt": [
        "Get price for mens blue shorts",
        "Get product details and price for floral dress",
        "Get price for garden furniture",
        "Get product details and price for oled tv",
        "Get price for dishwasher",
    ],
    "reference_trajectory": [
        [
            {
                "tool_name": "get_product_price",
                "tool_input": {"product_name": "mens blue shorts"},
            }
        ],
        [
            {
                "tool_name": "get_product_details",
                "tool_input": {"product_name": "floral dress"},
            },
            {
                "tool_name": "get_product_price",
                "tool_input": {"product_name": "floral dress"},
            },
        ],
        [
            {
                "tool_name": "get_product_price",
                "tool_input": {"product_name": "garden furniture"},
            }
        ],
        [
            {
                "tool_name": "get_product_details",
                "tool_input": {"product_name": "oled tv"},
            },
            {
                "tool_name": "get_product_price",
                "tool_input": {"product_name": "oled tv"},
            },
        ],
        [
            {
                "tool_name": "get_product_price",
                "tool_input": {"product_name": "dishwasher"},
            }
        ]
    ]
}
eval_sample_dataset = pd.DataFrame(eval_data)

```
EXPERIMENT_RUN = "qwiklabs-gcp-00-a45b05279191-single-tool-use"

single_tool_usage_metrics = [TrajectorySingleToolUse(tool_name="get_product_price")]

single_tool_call_eval_task = EvalTask(
    dataset=eval_sample_dataset,
    metrics=single_tool_usage_metrics,
)

single_tool_call_eval_result = single_tool_call_eval_task.evaluate(
    runnable=remote_1p_agent, experiment_run_name=EXPERIMENT_RUN
)
# View result
display(single_tool_call_eval_result.metrics_table)

```
trajectory_metrics = [
    "trajectory_exact_match",
    "trajectory_in_order_match",
    "trajectory_any_order_match",
    "trajectory_recall",
]
EXPERIMENT_RUN = "qwiklabs-gcp-00-a45b05279191-agent-trajectory-evaluation"

trajectory_eval_task = EvalTask(
    dataset=eval_sample_dataset,
    metrics=trajectory_metrics,
)

trajectory_eval_result = trajectory_eval_task.evaluate(
    runnable=remote_1p_agent,
    experiment_run_name=EXPERIMENT_RUN
)
# View result
display(trajectory_eval_result.metrics_table)
```
```
response_metrics = ["safety", "coherence"]
EXPERIMENT_RUN = "qwiklabs-gcp-00-a45b05279191-agent-response-evaluation"

response_eval_task = EvalTask(
    dataset=eval_sample_dataset,
    metrics=response_metrics,
)

response_eval_result = response_eval_task.evaluate(
    runnable=remote_1p_agent,
    experiment_run_name=EXPERIMENT_RUN
)

display(response_eval_result.metrics_table)

```

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
