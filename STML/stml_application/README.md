# stml_application

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

-------------------------------------------
Dementia Resources Feature Requirements
-----------------------------------------
Add the following to .env file:

#!!!!!!!!!!!!!!!!!!!!

Enter Google Search Engine API Key
GOOGLE_SEARCH_API_KEY = api_key_goes_here
SEARCH_ENGINE_ID = search_engine_id_goes_here
#!!!!!!!!!!!!!!!!!!!!

To get API key - https://developers.google.com/custom-search/v1/introduction#identify_your_application_to_google_with_api_key

To set up search engine: https://programmablesearchengine.google.com/about/

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
RETURNMEHOME FUNCTIONALITY REQUIREMENTS Running the ReturnMeHome function requires the use of a proxy server to route API requests due to Cross Origin Resource Sharing headers If the user has node.js installed, they can run the following commands in the server directory from the CLI

npm init -y npm install express request cors

From there, ensure the server.js file contains the code that lives inside this repo

From the terminal within the server directory use the following command to run the server: node server.js

That server needs to be running to route requests properly to the google api endpoint