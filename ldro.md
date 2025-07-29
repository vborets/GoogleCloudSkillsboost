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
