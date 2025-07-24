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

````
# Define a function to add two numerical inputs and return the result.
def add_numbers(a: float, b: float) -> float:
    print("Calling add function")
    return a + b

# Define a function to multiply two numerical inputs and return the result.
def multiply_numbers(a: float, b: float) -> float:
    print("Calling multiply function")
    return a * b

# Create FunctionDeclarations for your functions
add_function = FunctionDeclaration(
    name="add_numbers",
    description="Adds two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

multiply_function = FunctionDeclaration(
    name="multiply_numbers",
    description="Multiplies two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

# Define a math Tool with the add and multiply functions
math_tool = Tool(
    function_declarations=[add_function, multiply_function],
)

# Initialize the model with gemini-2.0-flash-001
model = GenerativeModel(
    "gemini-2.0-flash-001",  # Updated model name
    tools=[math_tool],
    generation_config=GenerationConfig(temperature=0),
    system_instruction="""Fulfill the user's instructions, including telling jokes.
    If asked to add or multiply numbers, call the provided functions.
    You may call one function after the other if needed.
    Repeat the result to the user.""",
)

# Start a new chat
chat = model.start_chat()

# Define function to handle the response from the model
def handle_response(response):
    # If there is a function call then invoke it
    # Otherwise print the response.
    if response.candidates[0].function_calls:
        function_call = response.candidates[0].function_calls[0]
    else:
        print(response.text)
        return

    # Complete the following sections
    if function_call.name == "add_numbers":
        # Extract the arguments to use in your function
        a = function_call.args["a"]
        b = function_call.args["b"]
        # Call your function
        result = add_numbers(a, b)
        # Send the result back to the chat session with the model
        response = chat.send_message(
            Content(role="user", parts=[Part.from_function_response(function_call.name, result)])
        )
        # Make a recursive call of this handler function
        handle_response(response)

    elif function_call.name == "multiply_numbers":
        # Extract the arguments to use in your function
        a = function_call.args["a"]
        b = function_call.args["b"]
        # Call your function
        result = multiply_numbers(a, b)
        # Send the result back to the chat session with the model
        response = chat.send_message(
            Content(role="user", parts=[Part.from_function_response(function_call.name, result)])
        )
        # Make a recursive call of this handler function
        handle_response(response)

    else:
        # You shouldn't end up here
        print(function_call)
````


```
from vertexai.generative_models import (
    FunctionDeclaration,
    Tool,
    GenerativeModel,
    GenerationConfig,
    Content,
    Part,
)

# Define a function to add two numerical inputs and return the result.
def add_numbers(a: float, b: float) -> float:
    print("Calling add function")
    return a + b

# Define a function to multiply two numerical inputs and return the result.
def multiply_numbers(a: float, b: float) -> float:
    print("Calling multiply function")
    return a * b

# Create FunctionDeclarations for your functions
add_function = FunctionDeclaration(
    name="add_numbers",
    description="Adds two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

multiply_function = FunctionDeclaration(
    name="multiply_numbers",
    description="Multiplies two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

# Define a math Tool with the add and multiply functions
math_tool = Tool(
    function_declarations=[add_function, multiply_function],
)

# Initialize the model with gemini-2.0-flash-001
model = GenerativeModel(
    "gemini-2.0-flash-001",  # Updated model name
    tools=[math_tool],
    generation_config=GenerationConfig(temperature=0),
    system_instruction="""Fulfill the user's instructions, including telling jokes.
    If asked to add or multiply numbers, call the provided functions.
    You may call one function after the other if needed.
    Repeat the result to the user.""",
)

# Start a new chat
chat = model.start_chat()

# Define function to handle the response from the model
def handle_response(response):
    # If there is a function call then invoke it
    # Otherwise print the response.
    if not response.candidates:
        print("No response from model")
        return
        
    candidate = response.candidates[0]
    
    if candidate.content.parts[0].text:
        print(candidate.content.parts[0].text)
        return
        
    if candidate.function_calls:
        for function_call in candidate.function_calls:
            if function_call.name == "add_numbers":
                # Extract the arguments to use in your function
                a = function_call.args["a"]
                b = function_call.args["b"]
                # Call your function
                result = add_numbers(a, b)
                # Send the result back to the chat session with the model
                response = chat.send_message(
                    Content(role="user", parts=[Part.from_function_response(
                        name=function_call.name,
                        response={"result": result}
                    )])
                )
                # Make a recursive call of this handler function
                handle_response(response)

            elif function_call.name == "multiply_numbers":
                # Extract the arguments to use in your function
                a = function_call.args["a"]
                b = function_call.args["b"]
                # Call your function
                result = multiply_numbers(a, b)
                # Send the result back to the chat session with the model
                response = chat.send_message(
                    Content(role="user", parts=[Part.from_function_response(
                        name=function_call.name,
                        response={"result": result}
                    )])
                )
                # Make a recursive call of this handler function
                handle_response(response)
            else:
                # You shouldn't end up here
                print(f"Unknown function call: {function_call.name}")

# Test that the model responds with its own answer for non-math related questions
print("Testing joke telling:")
response = chat.send_message("Tell me a joke?")
handle_response(response)

# Test the model with pizza slices calculation
print("\nTesting pizza slices calculation:")
response = chat.send_message("I have 7 pizzas each with 16 slices. How many slices do I have?")
handle_response(response)

# Test addition of pizzas
print("\nTesting pizza addition:")
response = chat.send_message("Doug brought 3 pizzas. Andrew brought 4 pizzas. How many pizzas did they bring together?")
handle_response(response)

# Test combined addition and multiplication
print("\nTesting combined operations:")
response = chat.send_message("""Doug brought 3 pizzas. Andrew brought 4 pizzas. 
                            There are 16 slices per pizza. How many slices are there?""")
handle_response(response)

# Test subtraction scenario
print("\nTesting subtraction (should be handled by model, not functions):")
response = chat.send_message("Doug brought 4 pizzas, but Andrew dropped 2 on the ground. How many pizzas are left?")
handle_response(response)
```
```
# First, install and import required packages
! pip3 install --upgrade --quiet --user google-cloud-aiplatform==1.88.0

# Restart kernel after installs
import IPython
app = IPython.Application.instance()
app.kernel.do_shutdown(True)

# Now run the imports and setup
import vertexai
from vertexai.generative_models import (
    Content,
    FunctionDeclaration,
    GenerationConfig,
    GenerativeModel,
    Part,
    Tool,
)

# Initialize Vertex AI
PROJECT_ID = ! gcloud config get-value project
PROJECT_ID = PROJECT_ID[0]
LOCATION = "us-central1"

vertexai.init(project=PROJECT_ID, location=LOCATION)

# Define the math functions with print statements
def add_numbers(a: float, b: float) -> float:
    print("Calling add function")
    return a + b

def multiply_numbers(a: float, b: float) -> float:
    print("Calling multiply function")
    return a * b

# Create FunctionDeclarations
add_function = FunctionDeclaration(
    name="add_numbers",
    description="Adds two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

multiply_function = FunctionDeclaration(
    name="multiply_numbers",
    description="Multiplies two numbers",
    parameters={
        "type": "object",
        "properties": {
            "a": {"type": "number", "description": "The first number"},
            "b": {"type": "number", "description": "The second number"},
        },
        "required": ["a", "b"],
    },
)

# Create the math tool
math_tool = Tool(
    function_declarations=[add_function, multiply_function],
)

# Initialize the model
model = GenerativeModel(
    "gemini-2.0-flash-001",
    tools=[math_tool],
    generation_config=GenerationConfig(temperature=0),
    system_instruction="""Fulfill the user's instructions, including telling jokes.
    If asked to add or multiply numbers, call the provided functions.
    You may call one function after the other if needed.
    Repeat the result to the user.""",
)

# Start a new chat
chat = model.start_chat()

# Define function to handle responses
def handle_response(response):
    # Check if there are any candidates
    if not response.candidates:
        print("No response candidates found")
        return
        
    # Get the first candidate
    candidate = response.candidates[0]
    
    # Check for function calls
    if hasattr(candidate, 'function_calls') and candidate.function_calls:
        function_call = candidate.function_calls[0]
        
        if function_call.name == "add_numbers":
            a = function_call.args["a"]
            b = function_call.args["b"]
            result = add_numbers(a, b)
            # Send the result back as a dictionary
            response = chat.send_message(
                Content(
                    role="user",
                    parts=[
                        Part.from_function_response(
                            name=function_call.name,
                            response={"result": result}
                        )
                    ]
                )
            )
            handle_response(response)
            
        elif function_call.name == "multiply_numbers":
            a = function_call.args["a"]
            b = function_call.args["b"]
            result = multiply_numbers(a, b)
            # Send the result back as a dictionary
            response = chat.send_message(
                Content(
                    role="user",
                    parts=[
                        Part.from_function_response(
                            name=function_call.name,
                            response={"result": result}
                        )
                    ]
                )
            )
            handle_response(response)
            
    else:
        # Print regular text response
        print(candidate.content.parts[0].text)

# Now test with the prompts

# Test 1: Non-math question
print("\nTest 1: Tell me a joke?")
response = chat.send_message("Tell me a joke?")
handle_response(response)

# Test 2: Multiplication
print("\nTest 2: I have 7 pizzas each with 16 slices. How many slices do I have?")
response = chat.send_message("I have 7 pizzas each with 16 slices. How many slices do I have?")
handle_response(response)

# Test 3: Addition
print("\nTest 3: Doug brought 3 pizzas. Andrew brought 4 pizzas. How many pizzas did they bring together?")
response = chat.send_message("Doug brought 3 pizzas. Andrew brought 4 pizzas. How many pizzas did they bring together?")
handle_response(response)

# Test 4: Combined operations
print("\nTest 4: Doug brought 3 pizzas. Andrew brought 4 pizzas. There are 16 slices per pizza. How many slices are there?")
response = chat.send_message("Doug brought 3 pizzas. Andrew brought 4 pizzas. There are 16 slices per pizza. How many slices are there?")
handle_response(response)

# Test 5: Subtraction (not using our functions)
print("\nTest 5: Doug brought 4 pizzas, but Andrew dropped 2 on the ground. How many pizzas are left?")
response = chat.send_message("Doug brought 4 pizzas, but Andrew dropped 2 on the ground. How many pizzas are left?")
handle_response(response)
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
