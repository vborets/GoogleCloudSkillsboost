# Improve Customer and Agent Satisfaction with Agent Assist: Challenge Lab  
A Step-by-Step Detailed Solution Guide for Google Cloud Skills Boost

---

## Task 1: Deploy a Chatbot Using AI Application

1. **Open AI Applications Console:**  
   Navigate to [AI Application console](https://console.cloud.google.com/gen-app-builder/start).

2. **Create New Chat App:**  
   - Click **Create App**  
   - Select **Chat** for app type  
   - Enter:  
     - App name: `Agent Name`  
     - Company name: `Company Name`  
     - Region: `global`  
   - Click **Create**

3. **Add a Datastore:**  
   - In the left menu, click **Datastores**  
   - Click **Create Datastore**  
   - Name it `Datastore Name`  
   - Select **Load from Cloud Storage**  
   - Enter the provided Cloud Storage bucket URL  
   - Click **Create**  
   - Wait up to 10 minutes for documents to process

4. **Link Datastore to Your Agent:**  
   - Open your app settings for `Agent Name`  
   - In data sources, add the `Datastore Name` datastore  
   - Save changes

---

## Task 2: Add Escalation to a Human Agent

1. **Enable Logging:**  
   - In `Agent Name` settings, enable **Cloud Logging** and **Conversation History**.

2. **Update Default Welcome Intent:**  
   - Open **Default Start Flow → Default Welcome Intent**  
   - Replace welcome message with:  
     > Hi! I am your Cymbal Travel Assistant and I can assist you with information on our hotels in the Maldives or I can connect you with a human agent to help you book or cancel an appointment. How can I help?  
   - Remove all other messages from the intent

3. **Create Agent Transfer Intent:**  
   - Name it `Agent Transfer`  
   - Add training phrases:  
     - I want to book a hotel  
     - I want to cancel my hotel booking  
     - I want to book a room  
     - I want to cancel my reservation  
   - Response:  
     > Let me connect you with a human agent.  
   - Configure the intent to **transfer the conversation to a human agent** via a transfer page  
   - Set the route to the **Agent Transfer page**

---

## Task 3: Use Agent Assist for Summaries, Classification & Sentiment Analyses

1. **Open Agent Assist Console**

2. **Create Summarization Generator:**  
   - Name: `Conversation Summaries`  
   - Add all predefined sections  
   - Add a new section called `escalation_type` with values: booking, cancellation, escalation (single word only)

3. **Create Conversation Profile:**  
   - Name: `Summary and classification`  
   - Assign `Conversation Summaries` generator  
   - Enable **Sentiment Analysis**  
   - Enable virtual agent: `Agent Name`

4. **Test Using Simulator:**  
   - Simulate the sample conversation (greeting, hotel info queries, booking request)  
   - Confirm:  
     - Conversation summary generated  
     - Escalation type correctly identified  
     - Sentiment analysis displayed

---

## Task 4: Use Agent Assist for Training Human Agents on Responses

1. **Create Build-your-own-assist Tools:**

   - **Build your assistance** (for agent messages rewrite)  
     - Trigger: on agent messages  
     - Paste instructions with examples to rephrase responses professionally and empathetically

   - **Build your assistance1** (for customer booking/cancellation helper)  
     - Trigger: on customer messages  
     - Paste instructions to prompt info needed for booking/cancellation

2. **Create Conversation Profile:**  
   - Name: `Hotel booking assistant`  
   - Assign both assist tools  
   - Enable **Sentiment Analysis**  
   - Attach virtual agent: `Agent Name`

3. **Test in Simulator:**  
   - Test the conversation flow to confirm assists provide helpful suggestions and polite rewrites

---

## Task 5: Provide FAQs & Article Suggestions Using Agent Assist

1. **Create Knowledge Base:**  
   - Name: `Maldives information`  
   - Language: English  
   - Add article URL: [https://en.wikipedia.org/wiki/Maldives](https://en.wikipedia.org/wiki/Maldives)  
   - Enable for **FAQ** and **Article Suggestions**

2. **Create Conversation Profile:**  
   - Name: `Maldives information`  
   - Use above knowledge base  
   - Enable **Sentiment Analysis** and virtual agent `Agent Name`

---

## Task 6: Leverage Generative Knowledge Assist (GKA)

1. **Create Conversation Profile:**  
   - Name: `Hotels data store for suggestions`  
   - Enable **Generative Knowledge Assist**:  
     - Select datastore agent `Agent Name`  
     - Enable conversation augmented query  
     - Show all suggested queries  
   - Enable **Sentiment Analysis**  
   - Attach virtual agent: `Agent Name`

2. **Test in Simulator:**  
   - Enter conversation requesting information and booking  
   - Confirm GKA suggests informative responses from the datastore

---

## Additional Tips:

- Use **Check my progress** button often to track completion  
- Allow time for data and configuration changes to propagate  
- Utilize **Simulator** to validate each functionality  
- Refer to official Google Cloud documentation if needed

---

**Good luck completing your Challenge Lab!**
