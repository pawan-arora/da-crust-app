const functions = require("firebase-functions/v1");
const admin = require('firebase-admin');

exports.submitReviewWithCaptcha = functions
  .region('australia-southeast1')
  .https.onCall(async (data, context) => {
    
    const { name, rating, comment, recaptchaToken } = data;

    // 1. Check if the token exists (and ensure it's not our old test string)
    if (!recaptchaToken || recaptchaToken === "frontend_verified") {
      throw new functions.https.HttpsError('invalid-argument', 'Missing or invalid reCAPTCHA token.');
    }

    const secretKey = process.env.RECAPTCHA_SECRET_KEY; 
    const verifyUrl = "https://www.google.com/recaptcha/api/siteverify"; 

    try {
      // 2. Ask Google if the token is legitimate
      const payload = new URLSearchParams();
      payload.append('secret', secretKey);
      payload.append('response', recaptchaToken);

      const googleResponse = await fetch(verifyUrl, { 
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        // 🌟 2. Send the safely encoded string
        body: payload.toString()
      });
      
      const googleData = await googleResponse.json();

      // 3. If Google says it's a bot, throw a clear error
      if (!googleData.success) {
        console.error("reCAPTCHA failure:", googleData);
        const failReason = googleData['error-codes'] ? googleData['error-codes'].join(', ') : 'Unknown';
        throw new functions.https.HttpsError('permission-denied', `Google rejected token: ${failReason}`);
      }

      // 4. Token is valid! Save the review to the database.
      const cleanName = name.trim() === "" ? "Anonymous" : name.trim();
      
      await admin.firestore().collection('reviews').add({
        authorName: cleanName,
        rating: rating,
        comment: comment.trim(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: "Review published securely!" };

    } catch (error) {
      console.error("Error submitting review:", error);
      
      // Pass our specific HTTP errors through to the Flutter app
      if (error instanceof functions.https.HttpsError) {
        throw error; 
      }
      
      throw new functions.https.HttpsError('internal', 'Server error while verifying review.');
    }
});