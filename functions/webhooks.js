const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { processSuccessfulOrder } = require("./orderProcessor");

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
      // JWT format
      try {
        const base64Payload = cleaned.split(".")[1];
        const decoded       = Buffer.from(base64Payload, "base64").toString("utf8");
        const tokenData     = JSON.parse(decoded);

        const paymentData = typeof tokenData.payment === "string"
          ? JSON.parse(tokenData.payment)
          : tokenData.payment;

        status        = paymentData?.status;
        // ✅ merchantTransactionId is guaranteed in every Paymark response
        transactionId = paymentData?.merchantTransactionId;

        console.log("Decoded JWT — status:", status, "transactionId:", transactionId);
      } catch (jwtErr) {
        console.error("JWT decode failed:", jwtErr.message);
        return res.status(400).send("Invalid JWT payload");
      }
    } else {
      // Plain JSON fallback
      status        = req.body?.status;
      transactionId = req.body?.merchantTransactionId;
    }

    if (status === "AUTHORISED" && transactionId) {
      // ✅ Look up the real orderId from reverse lookup collection
      const txDoc = await admin.firestore()
        .collection("paymark_transactions")
        .doc(transactionId)
        .get();

      if (txDoc.exists) {
        const { orderId } = txDoc.data();
        console.log(`Processing Paymark order: ${orderId}`);
        await processSuccessfulOrder(orderId, "Paymark_OnlineEFTPOS");
      } else {
        console.warn("No paymark_transactions doc found for:", transactionId);
      }
    } else {
      console.log(`Webhook ignored — status: ${status}, transactionId: ${transactionId}`);
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error("Paymark Webhook Error:", error.message);
    return res.status(500).send(`Webhook error: ${error.message}`);
  }
});