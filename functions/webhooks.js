const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { processSuccessfulOrder } = require("./orderProcessor");
const jwt = require("jsonwebtoken");

// =========================================================================
// 1. Stripe Webhook
// =========================================================================
exports.stripeWebhook = functions.region("australia-southeast1").https.onRequest(async (req, res) => {
  const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      req.headers["stripe-signature"],
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "checkout.session.completed") {
    const orderId = event.data.object.metadata.orderId;
    if (orderId) {
      try {
        await processSuccessfulOrder(orderId, "Stripe");
      } catch (error) {
        console.error("Database error:", error);
        return res.status(500).send("Database processing error");
      }
    }
  }
  res.status(200).json({ received: true });
});

// =========================================================================
// 2. Paymark Online EFTPOS Webhook
// =========================================================================
exports.worldlineWebhook = functions.region("australia-southeast1").https.onRequest(async (req, res) => {
  try {
    console.log("PAYMARK WEBHOOK RAW BODY:", JSON.stringify(req.body));

    let status;
    let transactionId;

    const rawBody = typeof req.body === "string" ? req.body : JSON.stringify(req.body);
    const cleaned = rawBody.replace(/^"|"$/g, "");

    if (cleaned.includes(".")) {
      // 🌟 Cryptographically VERIFY the JWT Signature
      try {
        const apiSecret = process.env.WORLDLINE_SECRET_API_KEY;
        
        // jwt.verify automatically checks the signature AND decodes the payload
        const decoded = jwt.verify(cleaned, apiSecret);
        
        const paymentData = typeof decoded.payment === "string"
          ? JSON.parse(decoded.payment)
          : decoded.payment;

        status = paymentData?.status;
        transactionId = paymentData?.merchantTransactionId;
        
        console.log("Decoded & Verified JWT — status:", status, "transactionId:", transactionId);

      } catch (jwtErr) {
        console.error("JWT Verification failed! Potential hacking attempt:", jwtErr.message);
        // Immediately reject the request if the signature is invalid
        return res.status(403).send("Forbidden: Invalid Signature");
      }
    } else {
      // Plain JSON fallback
      status = req.body?.status;
      transactionId = req.body?.merchantTransactionId;
    }

    // 🌟 1. Handle SUCCESS
    if (status === "AUTHORISED" && transactionId) {
      const txDoc = await admin.firestore().collection("paymark_transactions").doc(transactionId).get();
      
      if (txDoc.exists) {
        const { orderId } = txDoc.data();
        console.log(`Processing Paymark order: ${orderId}`);
        await processSuccessfulOrder(orderId, "Paymark_OnlineEFTPOS");
      } else {
        console.warn("No paymark_transactions doc found for:", transactionId);
      }
      
    // 🌟 2. Handle FAILURES (Declined by user, Timer Expired, or Bank Error)
    } else if (["DECLINED", "EXPIRED", "ERROR"].includes(status) && transactionId) {
      const txDoc = await admin.firestore().collection("paymark_transactions").doc(transactionId).get();
      
      if (txDoc.exists) {
        const { orderId } = txDoc.data();
        console.log(`Paymark payment ${status} for order: ${orderId}. Updating database...`);
        
        const firestoreStatus = status === "DECLINED" ? "DECLINED" : "FAILED";
        await admin.firestore().collection("orders").doc(orderId).update({ status: firestoreStatus });
      } else {
        console.warn("No paymark_transactions doc found for failed transaction:", transactionId);
      }
      
    // 🌟 3. Handle anything else
    } else {
      console.log(`Webhook ignored — status: ${status}, transactionId: ${transactionId}`);
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error("Paymark Webhook Error:", error.message);
    return res.status(500).send(`Webhook error: ${error.message}`);
  }
});