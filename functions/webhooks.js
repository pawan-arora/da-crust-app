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
    // 1. Extract the raw JWT string
    let rawBody = req.body;
    let jwtString = typeof rawBody === 'string' ? rawBody : JSON.stringify(rawBody);
    jwtString = jwtString.replace(/^"|"$/g, ''); // Strip quotes if they exist

    if (!jwtString.includes('.')) {
      return res.status(400).send("Payload is not a valid JWT");
    }

    // 2. Split the JWT and decode the Payload (middle section)
    const base64Payload = jwtString.split('.')[1];
    const decodedPayload = Buffer.from(base64Payload, 'base64').toString('utf8');
    const tokenData = JSON.parse(decodedPayload);

    // 3. Paymark heavily stringifies the inner 'payment' object, parse it again
    const paymentData = JSON.parse(tokenData.payment);
    
    // 4. Extract exactly what we need
    const status = paymentData.status; 
    const orderId = paymentData.oepayment.reference; 

    // 5. Fire the success process
    if (status === "AUTHORISED" && orderId) {
      console.log(`Successfully processed Paymark order: ${orderId}`);
      await processSuccessfulOrder(orderId, "Paymark_OnlineEFTPOS");
    } else {
      console.warn(`Webhook ignored. Status: ${status}, OrderID: ${orderId}`);
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error("Paymark Webhook Error:", error.message);
    return res.status(500).send(`Webhook error: ${error.message}`);
  }
});