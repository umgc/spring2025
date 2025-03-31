/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Cloud Function to send notifications to a topic
exports.sendNotification = functions.https.onRequest((req, res) => {
  // Extract topic and message from the request body
  const topic = req.body.topic;
  const message = req.body.message;

  // Construct the notification payload
  const payload = {
    notification: {
      title: req.body.title,
      body: message,
    },
    topic: topic,
  };

  // Send the message to the topic using Firebase Admin SDK
  admin.messaging().send(payload)
      .then((response) => {
        console.log("Notification sent successfully:", response);
        res.status(200).send("Notification sent successfully!");
      })
      .catch((error) => {
        console.error("Error sending notification:", error);
        res.status(500).send("Error sending notification");
      });
});
