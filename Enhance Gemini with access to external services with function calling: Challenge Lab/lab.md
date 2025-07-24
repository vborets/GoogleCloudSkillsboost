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
# Define the functions with print statements as requested
def add_numbers(a: float, b: float) -> float:
    print("Calling add function")
    return a + b

def multiply_numbers(a: float, b: float) -> float:
    print("Calling multiply function")
    return a * b

# Create FunctionDeclarations with proper return types
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
    returns={
        "type": "object",
        "properties": {
            "result": {"type": "number", "description": "The sum of the two numbers"}
        }
    }
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
    returns={
        "type": "object",
        "properties": {
            "result": {"type": "number", "description": "The product of the two numbers"}
        }
    }
)

# Create the math tool
math_tool = Tool(
    function_declarations=[add_function, multiply_function],
)

# Initialize the model
model = GenerativeModel(
    "gemini-1.0-pro",  # Using gemini-1.0-pro as it's more stable for function calling
    tools=[math_tool],
    generation_config=GenerationConfig(temperature=0)
)

# Start chat
chat = model.start_chat()

# Corrected handle_response function
def handle_response(response):
    if not response.candidates or not response.candidates[0].content.parts:
        print("No response received")
        return
        
    # Check for function calls
    if hasattr(response.candidates[0], 'function_calls') and response.candidates[0].function_calls:
        function_call = response.candidates[0].function_calls[0]
        
        if function_call.name == "add_numbers":
            a = function_call.args["a"]
            b = function_call.args["b"]
            result = add_numbers(a, b)
            response = chat.send_message(
                Content(
                    role="user",
                    parts=[Part.from_function_response(
                        name=function_call.name,
                        response={"result": result}  # Must be a dictionary
                    )]
                )
            )
            handle_response(response)
            
        elif function_call.name == "multiply_numbers":
            a = function_call.args["a"]
            b = function_call.args["b"]
            result = multiply_numbers(a, b)
            response = chat.send_message(
                Content(
                    role="user",
                    parts=[Part.from_function_response(
                        name=function_call.name,
                        response={"result": result}  # Must be a dictionary
                    )]
                )
            )
            handle_response(response)
            
    else:
        # Print regular text response
        print(response.text)

# Test with the specific prompt
print("Testing with: 'I have 7 pizzas each with 16 slices. How many slices do I have?'")
response = chat.send_message("I have 7 pizzas each with 16 slices. How many slices do I have?")
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
