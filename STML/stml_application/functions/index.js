// Importing Firebase modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase with explicit configuration (if needed)
admin.initializeApp();

// Cloud Function: Send a notification upon the creation of a Firestore document
exports.sendNotificationOnHelpRequest = functions.firestore
    .document("helpRequests/{requestId}")
    .onCreate(async (snapshot, context) => {
      try {
        // Retrieve the data from the created document
        const requestData = snapshot.data();

        // Validate the data
        if (!requestData.userId || !requestData.location) {
          console.error("Invalid request data: userId or location missing");
          return;
        }

        const userId = requestData.userId;
        const location = requestData.location;

        // Retrieve caregiver information from Firestore
        const caregiverRef = admin.firestore()
            .collection("caregivers")
            .doc(userId);
        const caregiverDoc = await caregiverRef.get();

        // Check if the caregiver document exists
        if (!caregiverDoc.exists) {
          console.error(`Caregiver not found for userId: ${userId}`);
          return;
        }

        const caregiver = caregiverDoc.data();

        // Check if emergency notifications are enabled
        if (caregiver.enableEmergencyNotifications) {
          // Validate FCM token
          if (!caregiver.fcmToken) {
            console.error("No FCM token found for caregiver");
            return;
          }

          // Prepare the notification message
          const payload = {
            notification: {
              title: "Emergency Alert",
              body: `Help requested at ${location}`,
            },
            data: {
              type: "emergency",
              location: location,
              timestamp: new Date().toISOString(),
            },
          };

          // Send the notification to the caregiver
          await admin.messaging()
              .sendToDevice(caregiver.fcmToken, payload);
          console.log(
              `Notification sent to caregiver with userId: ${userId}`,
          );
        } else {
          console.log(
              `Emergency notifications are disabled for caregiver: ${userId}`,
          );
        }

        // Log the help request in the logs collection
        await admin.firestore().collection("helpLogs").add({
          userId: userId,
          location: location,
          timestamp: new Date().toISOString(),
          status: "sent",
        });

        console.log("Help request processed successfully");
      } catch (error) {
        // Log any errors that occur during execution
        console.error("Error processing help request:", error);
      }
    });
