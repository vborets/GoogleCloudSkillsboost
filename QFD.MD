# Solution for AI Applications Search and Conversation Tasks

## Task 1: Create a website search app

1. **Create the app**:
   - Navigate to AI Applications > Search in Google Cloud Console
   - Click "Create App"
   - Set App Name to "App Name 1"
   - Select App Type: "Search"
   - Set Location: "Global"
   - Click "Continue"

2. **Configure datastore**:
   - Select "Create new datastore"
   - Name it "Datastore Name 1"
   - Select "Website" as data source
   - Enter URL pattern: `cloud.google.com/*`
   - Configure crawling settings (use defaults or customize as needed)
   - Click "Create"

3. **Preview and verify**:
   - Wait for initial indexing to complete (may take several minutes)
   - Click "Preview" on the app
   - Test search functionality with queries like "Compute Engine pricing"
   - Verify results are relevant to cloud.google.com content

## Task 2: Create a structured data search app

1. **Create the app**:
   - Navigate to AI Applications > Search
   - Click "Create App"
   - Set App Name to "App Name 2"
   - Select App Type: "Search"
   - Set Location: "Global"
   - Click "Continue"

2. **Configure datastore**:
   - Select "Create new datastore"
   - Name it "Datastore Name 2"
   - Select "Cloud Storage" as data source
   - Enter bucket path: `cloud-samples-data/gen-app-builder/search/kaggle_movies/movie_metadata.ndjson`
   - Select file format: "Newline Delimited JSON"
   - Click "Create"

3. **Configure search results display**:
   - After datastore is created, go to "Search Results Configuration"
   - Map fields as follows:
     - Key: `title` → Display as "Title"
     - Value: `poster_path` → Display as "Thumbnail"
     - Text 1: `tagline` 
     - Text 2: `revenue`
   - Save configuration

4. **Preview and verify**:
   - Click "Preview" on the app
   - Test search with movie titles or keywords
   - Verify results show the configured fields correctly

## Task 3: Create an unstructured data search app

1. **Create the app**:
   - Navigate to AI Applications > Search
   - Click "Create App"
   - Set App Name to "App Name 3"
   - Select App Type: "Search"
   - Set Location: "Global"
   - Click "Continue"

2. **Configure datastore**:
   - Select "Create new datastore"
   - Name it "Datastore Name 3"
   - Select "Cloud Storage" as data source
   - Enter bucket path: `cloud-samples-data/gen-app-builder/search/alphabet-investor-pdfs`
   - Select file format: "Unstructured Documents"
   - Click "Create"

3. **Preview and verify**:
   - Wait for document processing to complete
   - Click "Preview" on the app
   - Test search with terms like "quarterly earnings" or "capital allocation"
   - Verify PDF content is being searched and returned

## Task 4: Create a generative chat application

1. **Enable APIs**:
   - Navigate to APIs & Services > Library
   - Search for and enable:
     - Dialogflow API
     - AI Applications API

2. **Create conversational agent**:
   - Navigate to AI Applications > Conversation
   - Click "Create Agent"
   - Use existing agent named "Agent Name"
   - Select your project
   - Click "Create"

3. **Configure datastore**:
   - In the agent settings, go to "Data Stores"
   - Click "Add Data Store"
   - Name it "Datastore Name 4"
   - Select "Cloud Storage" as data source
   - Enter bucket path: `cloud-samples-data/gen-app-builder/search/alphabet-investor-pdfs`
   - Select file format: "Unstructured Documents"
   - Click "Create"
   - Wait for indexing to complete (up to 10 minutes)

4. **Configure flow**:
   - Go to Conversational Agents > Flows
   - Select "Start Page"
   - Add a "Data Store" state handler
   - Select "Datastore Name 4" as the data source
   - Save the flow

5. **Test the agent**:
   - Start an interactive session with the chatbot
   - Test with:
     - Greeting: "Hello"
     - Questions:
       - "What was the revenue for Google in 2004?"
       - "Where does Google see the most potential opportunity for long term growth?"
       - "Where is Google allocating the most amount of its capital?"
   - Verify responses are based on the investor documents

## Task 5: Enhance customer engagement and optimize performance

1. **Integrate phone gateway**:
   - Navigate to AI Applications > Conversation > Agent Name > Integrations
   - Click "Add Integration"
   - Select "Telephony"
   - Name it "Phone Gateway Name"
   - Select country: "United States"
   - Configure phone number settings
   - Enable Speech-to-Text and Text-to-Speech
   - Save configuration

2. **Embed chat widget**:
   - In the same Integrations section
   - Click "Add Integration"
   - Select "Web Demo"
   - Copy the provided HTML snippet
   - Paste it into your website's HTML code
   - Test the widget on your website

3. **Enable interaction logging**:
   - Navigate to AI Applications > Conversation > Agent Name > Settings
   - Find "Interaction Logging" section
   - Enable "Conversation History"
   - Enable "Analytics"
   - Configure logging settings as needed
   - Save settings

4. **View analytics**:
   - Navigate to AI Applications > Conversation > Analytics
   - Review conversation history, response metrics
   - Identify common failure points or friction areas
   - Use insights to improve agent responses and flows

## Verification

After completing each task, use the "Check my progress" buttons in the lab interface to verify you've completed each objective correctly. For tasks involving indexing (especially Tasks 3 and 4), remember that it may take several minutes for the data to become searchable after configuration.
