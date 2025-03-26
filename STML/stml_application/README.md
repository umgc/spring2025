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
-------------------------------------------
Add the following to .env file:

#!!!!!!!!!!!!!!!!!!!!

Enter Google Search Engine API Key
GOOGLE_SEARCH_API_KEY = api_key_goes_here
SEARCH_ENGINE_ID = search_engine_id_goes_here
#!!!!!!!!!!!!!!!!!!!!

To get API key - https://developers.google.com/custom-search/v1/introduction#identify_your_application_to_google_with_api_key

To set up search engine: https://programmablesearchengine.google.com/about/

------------------------------------------------------
Fitbit Integration - iOS App Only For Now (03/23/2025)
------------------------------------------------------
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
7. Save the app and copy the Client ID Client Secret, and redirectUri
8. Open fitbit_login.dart file in lib/src/features/wearable-integration
9. Replace the clientID, clientSecret, and redirectUri with your own in the fitbitCredentials object
10. Go to ios/Runner and open up Runner.xcodeproj
11. Click on the project Runner and select Runner under Targets, go to Info and scroll down to URL Types
- Add this to URL Identifier: com.stml and this to URL Schemes: stmlapp
12. Close the Xcode project and you should be all setup!