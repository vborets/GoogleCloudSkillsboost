Below is a comprehensive step-by-step solution for each task as described in your prompt, structured for clarity and direct applicability in the Google Cloud Gen App Builder console.

# Task 1: Deploy a Chatbot Using AI Application

### 1. Create the Conversational Agent
- In the [AI Applications console](https://console.cloud.google.com/gen-app-builder/start):
  - Click **“Create new app”**.
  - Choose **App Type**: `Chat`.
  - **Agent Name**: Enter your desired agent name (e.g., `Cymbal Travel Assistant`).
  - **Company Name**: Enter your company’s name (e.g., `Cymbal`).
  - **Region**: Select `global`.

### 2. Add a Data Store
- In your new app, go to the **Data Store** section.
- Click **“Add data store”**, name it `Datastore Name`.
- Choose **Unstructured PDF** as the data type.
- Specify the location of your PDFs in your **Cloud Storage bucket**.
- Complete the setup to load the documents. (Wait up to 10 minutes for indexing.)

### 3. Connect Data Store to Agent
- In Agent settings, ensure to **use the data store** you created so the agent can answer questions about your hotels using the information from your PDFs.

# Task 2: Add an Escalation to a Human Agent

### 1. Enable Logging and Conversation History
- In your agent's settings, enable:
  - **Cloud Logging**
  - **Conversation History**

### 2. Edit Default Welcome Intent
- In **Default Start Flow**, select **Default Welcome Intent**.
  - Set the greeting message to ONLY:
    > Hi! I am your Cymbal Travel Assistant and I can assist you with information on our hotels in the Maldives or I can connect you with a human agent to help you book or cancel an appointment. How can I help?
  - Remove any other messages.

### 3. Create Agent Transfer Intent
- Create a new intent named **Agent Transfer**.
  - Add the following *training phrases*:
    - I want to book a hotel
    - I want to cancel my hotel booking
    - I want to book a room
    - I want to cancel my reservation
  - **Agent response**: Let me connect you with a human agent.
  - Configure action to **transfer to human agent**.
  - Set the route to finish on the **Agent Transfer page**.

# Task 3: Use Agent Assist for Summaries, Classification, and Sentiment Analyses

### 1. Create Summarization Generator
- In **Agent Assist Console**:
  - Create a *Summarization Generator*: Name it `Conversation Summaries`.
  - Select all predefined sections.
  - Add a section named `escalation_type` as a single-word category (`booking`, `cancellation`, or `escalation`).

### 2. Create Conversation Profile
- Create **Conversation Profile**: Name it `Summary and classification`.
  - Use the `Conversation Summaries` generator.
  - Enable **Sentiment Analysis**.
  - Enable the virtual agent (`Agent Name`).

### 3. Test With Simulator
- Simulate the conversation flow outlined in your prompt.
- At the end, confirm:
  - The **summary** is generated.
  - **Escalation Type** populates correctly (e.g., `booking`).
  - Sentiment analysis works (e.g., N for incomplete).

# Task 4: Use Agent Assist for Training Human Agents

### 1. Build Assistants for Agent Training

#### Assistant 1: Professional Rewriter
- **Build-your-own-assist**
  - Name: `Build your assistance`
  - Reacts **when agent sends messages**
  - Paste the provided instruction set for rewriting agent responses.

#### Assistant 2: Booking/Cancellation Guidelines
- **Build-your-own-assist**
  - Name: `Build your assistance1`
  - Reacts **when customer sends messages**
  - Use the provided instructions for booking and cancellation guidance.

### 2. Create Conversation Profile
- Name: `Hotel booking assistant`.
  - Use both assists: `Build your assistance1` and `Build your assistance`.
  - Enable **Sentiment Analysis**.
  - Enable the virtual agent.

### 3. Test in Simulator
- Run through the scenario to verify that both assists trigger at the correct times, providing both rephrased responses and guidance for the agent.

# Task 5: Provide FAQs and Article Suggestions Using Agent Assist

### 1. Create Knowledge Base
- Name: `Maldives information`.
- Add **Article Suggestions and FAQ** using this public URL: https://en.wikipedia.org/wiki/Maldives

### 2. Create Conversation Profile
- Name: `Maldives information`.
  - Use the above knowledge base for article suggestions and FAQ.
  - Enable **Sentiment Analysis**.
  - Enable the virtual agent.

*Note: It may take up to a day for new FAQs and articles to be available.*

# Task 6: Leverage Generative Knowledge Assist (GKA)

### 1. Create Conversation Profile for Suggestions
- Name: `Hotels data store for suggestions`.
  - Under **Feature Configuration**:
    - **Generative Knowledge Assist**: Select your datastore agent (`Agent Name`), enable *conversation augmented query*, and *show all suggested queries for conversation*.
    - **Sentiment analysis**: ENABLE
    - **Virtual agent**: `Agent Name`

### 2. Test in Simulator
- Run the provided scenario and verify that [Generative Knowledge Assist] suggestions appear, offering detailed hotel info when the customer asks for it.

**When finished with each configuration in the console, use the "Check my progress" button to validate your completion for every task.**

````
