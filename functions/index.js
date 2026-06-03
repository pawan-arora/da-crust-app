const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

let twilioClient;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  twilioClient = require("twilio")(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN,
    { region: "au1" }
  );
}

// =========================================================================
// 1. Create Checkout Session (Stripe & Afterpay)
// =========================================================================
exports.createCheckoutSession = functions.region("australia-southeast1").https.onCall(async (data, context) => {
  const stripeKey = process.env.STRIPE_SECRET_KEY;
  const stripe = require("stripe")(stripeKey);

  try {
    const payload = data.amount !== undefined ? data : (data.data || {});
    const { amount, orderId, scheduledTimeEpoch, paymentMethod } = payload;

    const finalAmountInCents = Math.round(Number(amount) * 100);
    const currentEnv = process.env.APP_ENV || "local";
    const environments = {
      local: process.env.LOCAL_URL,
      dev:   process.env.DEV_URL,
      qa:    process.env.QA_URL,
      prod:  process.env.PROD_URL,
    };
    const DOMAIN = environments[currentEnv] || "https://dacrust.co.nz";

    // 🌟 THE FIX: Isolate the payment methods entirely
    let stripeMethods;
    if (paymentMethod === "afterpay") {
      stripeMethods = ["afterpay_clearpay"]; // Forces Stripe to drop the card form and show Afterpay rails
    } else {
      stripeMethods = ["card"]; // Keeps standard card flow isolated
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: stripeMethods,
      line_items: [{
        price_data: {
          currency: "nzd", // Kept native to prevent conversion conflicts
          product_data: { name: `Da Crust Order #${orderId}` },
          unit_amount: finalAmountInCents,
        },
        quantity: 1,
      }],
      mode: "payment",
      success_url: `${DOMAIN}/#/success?orderId=${orderId}`,
      cancel_url:  `${DOMAIN}/#/failed`,
      metadata: { orderId: orderId },
    });

    return { url: session.url };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// =========================================================================
// 2. Create Paymark Online EFTPOS Session
// =========================================================================
exports.createOnlineEftposSession = functions.region("australia-southeast1").https.onCall(async (data, context) => {
  try {
    const payload = data.amount !== undefined ? data : (data.data || {});
    const { amount, orderId } = payload;
    const finalAmountInCents = Math.round(Number(amount) * 100);

    const merchantId = process.env.WORLDLINE_MERCHANT_ID;
    const apiKey     = process.env.WORLDLINE_API_KEY_ID;
    const apiSecret  = process.env.WORLDLINE_SECRET_API_KEY;

    const currentEnv = process.env.APP_ENV || "local";
    const environments = {
      local: process.env.LOCAL_URL,
      dev:   process.env.DEV_URL,
      qa:    process.env.QA_URL,
      prod:  process.env.PROD_URL,
    };
    const DOMAIN = environments[currentEnv] || "https://dacrust.co.nz";

    let userIp = "127.0.0.1";
    if (context.rawRequest && context.rawRequest.ip) {
      const ipv4Match = context.rawRequest.ip.match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/);
      if (ipv4Match) userIp = ipv4Match[0];
    }
    const userAgentString = context.rawRequest ? context.rawRequest.get("user-agent") || "Mozilla/5.0 (Server)" : "Mozilla/5.0 (Server)";

    const credentials = Buffer.from(`${apiKey}:${apiSecret}`).toString("base64");
    const tokenResponse = await fetch("https://apitest.paymark.nz/bearer", {
      method: "POST",
      headers: {
        "Authorization": `Basic ${credentials}`,
        "Content-Type":  "application/x-www-form-urlencoded",
      },
      body: "grant_type=client_credentials",
    });

    if (!tokenResponse.ok) throw new Error(`Auth failed: ${await tokenResponse.text()}`);
    const tokenData = await tokenResponse.json();

    const transactionId = crypto.randomUUID();

    const intentPayload = {
      merchantTransactionId: transactionId,
      integrationMode: "HOSTED",
      merchant: {
        url:             DOMAIN,
        redirectUrl:     `${DOMAIN}/#/success?orderId=${orderId}`,
        notificationUrl: "https://australia-southeast1-da-crust-dev.cloudfunctions.net/worldlineWebhook",
        merchantId:      merchantId,
      },
      oepayment: {
        amount:       finalAmountInCents,
        currency:     "NZD",
        reference:    orderId.toString().slice(0, 12), // The webhook will read this back!
      },
      risk: {
        userAgentInfo: { userAgent: userAgentString, userIpAddress: userIp }
      }
    };

    const intentResponse = await fetch("https://apitest.paymark.nz/oe/transactions/v2/payments/create-intent", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${tokenData.access_token}`,
        "Content-Type":  "application/json",
      },
      body: JSON.stringify(intentPayload),
    });

    if (!intentResponse.ok) throw new Error(`Intent failed: ${await intentResponse.text()}`);
    const intentData = await intentResponse.json();

    await admin.firestore().collection("orders").doc(orderId).update({
      status:    "PENDING_EFTPOS",
      paymarkId: intentData.paymentId,
    });

    // 🌟 REMOVED the paymark_transactions write completely!

    return { url: intentData.paymentUrl };
  } catch (error) {
    console.error("Paymark Error:", error.message);
    throw new functions.https.HttpsError("internal", `Failed: ${error.message}`);
  }
});

// =========================================================================
// 3. Webhooks (externalized)
// =========================================================================
const webhooks = require("./webhooks");
exports.stripeWebhook    = webhooks.stripeWebhook;
exports.worldlineWebhook = webhooks.worldlineWebhook;

// =========================================================================
// 4. Background Triggers
// =========================================================================
exports.sendSmsNotification = functions.region("australia-southeast1").firestore
  .document("sms_messages/{docId}")
  .onCreate(async (snapshot, context) => {
    if (!twilioClient) return snapshot.ref.update({ deliveryState: "ERROR" });
    try {
      const response = await twilioClient.messages.create({
        body: snapshot.data().body,
        from: process.env.TWILIO_PHONE_NUMBER,
        to:   snapshot.data().to,
      });
      return snapshot.ref.update({
        deliveryState:    "SUCCESS",
        twilioMessageSid: response.sid,
      });
    } catch (error) {
      return snapshot.ref.update({
        deliveryState: "ERROR",
        errorMessage:  error.message,
      });
    }
  });

exports.submitReviewWithCaptcha = require("./reviewHandler").submitReviewWithCaptcha;