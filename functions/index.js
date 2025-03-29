const functions = require("firebase-functions");  
const admin = require("firebase-admin");  
admin.initializeApp();  

exports.sendHelpAlert = functions.https.onCall(async (data, context) => {  
  const {caregiverToken, location, userId, userName} = data;  
  
  if (!caregiverToken) {  
    return {success: false, error: "Token du caregiver manquant"};  
  }  

  try {  
    const latitude = location && location.latitude ? location.latitude.toString() : "";  
    const longitude = location && location.longitude ? location.longitude.toString() : "";  
    const address = location && location.address ? location.address : "";  
    
    await admin.messaging().send({  
      token: caregiverToken,  
      notification: {  
        title: "URGENT: Help Needed!",  
        body: `${userName || "A user"} needs help immediately!`  
      },  
      data: {  
        type: "help_request",  
        userId: userId || "",  
        latitude: latitude,  
        longitude: longitude,  
        address: address,  
        timestamp: new Date().toISOString()  
      }  
    });  
    
    return {success: true};  
  } catch (error) {  
    console.error("Error sending message:", error);  
    return {success: false, error: error.message};  
  }  
});  