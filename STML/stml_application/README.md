## MemoryMinder - STML for Team C/D Spring 2025
# MemoryMinder: Short-Term Memory Loss ​(STML) Application

What is STML? 
- The inability to recall information or events that recently occurred​

Purpose of App​
- To improve the quality of life for persons with STML. ​

- Assist caregivers (non-medical or geriatric assistant professionals) such as relatives, friends, etc., with helping individuals with STML​

Main users for the application:​
- Caregiver ​
- Care recipient ​

NOTE: Current code base stems from Fall 23 – CogniOpen​

## Getting Started

Refer to Team C/D documentation for further insight. All available documentation is located here:
https://umgc-cappms.azurewebsites.net/previousprojects

Spring 2025 Team C - Minder
Spring 2025 Team D - MemoryMinder


## To assist with running the app please do the following: 
# -------------------------------------------
# Dementia Resources Feature Requirements
# -------------------------------------------
Add the following to .env file:

#!!!!!!!!!!!!!!!!!!!!

Enter Google Search Engine API Key
GOOGLE_SEARCH_API_KEY = api_key_goes_here
SEARCH_ENGINE_ID = search_engine_id_goes_here
#!!!!!!!!!!!!!!!!!!!!

To get API key - https://developers.google.com/custom-search/v1/introduction#identify_your_application_to_google_with_api_key

To set up search engine: https://programmablesearchengine.google.com/about/

# ------------------------------------------------------
# Fitbit Integration - iOS App Only For Now (03/23/2025)
# ------------------------------------------------------
1. Create a Fitbit Developer Account here: https://dev.fitbit.com/
2. Sign in and Agree to the Developer Terms of Service
3. Go to: https://dev.fitbit.com/apps and click "Register a new app"
4. Fill out the information accordingly
- Example of what we used:
    - Application Name: STML
    - Description: App used for short term memory loss people to view quick health metrics.
    - Application Website URL: https://yourapp-placeholder.com
    - Organization: UMGC
    - Organization Website URL: https://www.umgc.edu/
    - Terms of Service URL: https://yourapp-placeholder.com
    - Privacy Policy URL: https://yourapp-placeholder.com
    - OAuth 2.0 Type: Server
    - Redirect URL: stmlapp://yourname
    - Default Access Type: Read Only
5. Agree to terms of service
6. Click "Register"
7. Save the app and copy the Client ID, Client Secret, and redirectUri
8. Go to your .env file and dd this line to the file:
#!!!!!!!!!!!!!!!!!!!!
# Enter Fitbit API Key
FITBIT_CLIENT_ID=
FITBIT_CLIENT_SECRET=
#!!!!!!!!!!!!!!!!!!!!
9. Paste the Client ID and Client Secret that you copied over into this place in the .env
10. Go to ios/Runner and open up Runner.xcodeproj
11. Click on the project Runner and select Runner under Targets, go to Info and scroll down to URL Types
- Add this to URL Identifier: com.stml and this to URL Schemes: stmlapp
12. Close the Xcode project and you should be all setup!


# ------------------------------------------------------
# RETURNMEHOME FUNCTIONALITY REQUIREMENTS 
# ------------------------------------------------------
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
RETURNMEHOME FUNCTIONALITY REQUIREMENTS 
Running the ReturnMeHome function requires the use of a proxy server to route API requests due to Cross Origin Resource Sharing headers

If the user has node.js installed, they can run the following commands in the server directory from the CLI
#!!!!!!!!!!!!!!!!!!!!
npm init -y
npm install express request cors
#!!!!!!!!!!!!!!!!!!!!
From there, ensure the server.js file contains the code that lives inside this repo

From the terminal within the server directory use the following command to run the server:
node server.js

That server needs to be running to route requests properly to the google api endpoint