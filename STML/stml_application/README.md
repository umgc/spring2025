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

# Requirements for Spring 2025
Req 12​ - IN CURRENT APP
The application shall provide a help button in the STML user mode. [Discuss feature set]​

Req 20 (Nice to Have​) - NOT FUNCTIONING AS EXPECTED IN CURRENT APP
The application shall have a default language option of English and support additional multi language options. Note: minimum additional language – Spanish. ​

Req 29 ​- IN CURRENT APP
The application will provide a “Return me Home” function that enables the Admin/Caregiver the ability to “set” the home geo-location for the STML user in the STML user profile. In the STML user mode, the “Return me Home” function will provide option for walking or driving instructions from current STML user location to the STML home geo-location. The intent of this requirement it to provide the STML user with a very simple method to get directions home if they have become disoriented during a walk or local drive.  The feature should also notify the Admin/Caregiver of the current location of the STML user. ​

Look into ESRI geo-nav app. Make call to server ​

Req 30​ - IN CURRENT APP
The application will integrate with wearables – FitBit and Applewatch to share STML user health data with their admin/caregiver.​

Req 31​ - IN CURRENT APP
The application will alert the Admin/Caregiver and warn the STML user when sensitive PII information is identified in transcribed notes, such as, Potential triggers include: “My Social Security Number is,” “My Bank Account Number is,” “My Medicare number is,” “My credit card number is” Note: the development team needs to research and identify specific words or phrases that may indicate potential for the STML user to be victim of entitlement fraud activity. ​

Req 32 ​(Nice to Have)​ - IN CURRENT APP
The application will utilize AI to assess STML user transcribed notes of potential  scams to alert the Admin/Caregiver  Note: the development team needs to research and identify specific words or phrases that may indicate potential for the STML user to be victim of scam activity. ​

Tech support scams ​
Criminals pose as tech support representatives and offer to fix computer issues. They may gain remote access to the victim's device and sensitive information. Potential STML user triggers: “What’s wrong with my iPad or computer””What do you need me to do?””How much does it cost?” ​

Grandparent scams ​
Criminals pose as a relative, usually a grandchild, and claim to be in financial need.”What do you need me to do?””How much do you need me to send?” ​

Government impersonation scams ​
Criminals pose as government employees and threaten to arrest or prosecute victims unless they provide funds. “What did I do wrong?” ”What do I need to pay?” ​

Sweepstakes/lottery scams ​
Criminals claim to work for charitable organizations or that the victim has won a lottery or sweepstakes. They may ask the victim to pay a fee to collect the winnings. ”What do I need to pay?””How much do I need to send?” ​

Req 33 ​(Nice to Have)​ - IN CURRENT APP
Google “Resources for dementia caregivers.” Integrate with admin/caregiver and STML user (as applicable) functionality to enable customization by location to as many of these resources and services as possible.  ​

Req 34 (Nice to Have)​ - NOT IN CURRENT APP
The application shall have the ability to connect to any existing camera devices and be able to send camera data to caregiver; privacy settings ​

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

# ------------------------------------------------------
# Known Issues 
# ------------------------------------------------------
The Safety Zone of the Return Me Home feature only works on iOS as of 03/29/25 at 10:15 AM EST
https://github.com/umgc/spring2025/pull/286

The Language Localization feature was actively worked on but unable to be featured within the last presented demo for the Spring 2025 STML teams 
https://github.com/umgc/spring2025/pull/284

Due to time and resources this requirement was omitted 
Req 34 (Nice to Have)​ - NOT IN CURRENT APP
The application shall have the ability to connect to any existing camera devices and be able to send camera data to caregiver; privacy settings ​