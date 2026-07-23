const admin = require("firebase-admin");
const { buildReceiptHtml, buildOwnerEmailHtml } = require("./emailBuilder");
const { buildSmsString, buildOwnerSmsString } = require("./smsBuilder");

async function processSuccessfulOrder(orderId, paymentProvider) {
  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);

  const orderSnapshot = await orderRef.get();
  if (!orderSnapshot.exists) return false;

  const orderData = orderSnapshot.data();
  if (orderData.status === "PAID") return true;

  const restaurantQuery = await db.collection("restaurant").limit(1).get();
  let restaurantData = !restaurantQuery.empty ? restaurantQuery.docs[0].data() : {};

  const emailHtml = buildReceiptHtml(orderData, restaurantData);

  // Extract Owner contact info
  const ownerEmail = restaurantData.contact?.email;
  const ownerPhone = restaurantData.contact?.phone;

  // Get delay in seconds from restaurant document (default = 30)
  let delaySeconds = 30;
  if (restaurantData.ownerSmsDelaySeconds !== undefined && restaurantData.ownerSmsDelaySeconds !== null) {
    const parsed = Number(restaurantData.ownerSmsDelaySeconds);
    if (!isNaN(parsed) && parsed >= 0) {
      delaySeconds = parsed;
    }
  }

  const batch = db.batch();

  // 1. Update order status
  batch.update(orderRef, {
    status: "PAID",
    paymentProvider: paymentProvider,
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // --- CUSTOMER NOTIFICATIONS (instant) ---
  const mailRef = db.collection("mail").doc();
  batch.set(mailRef, {
    to: orderData.customerEmail,
    message: {
      subject: `Da Crust Order Confirmed: #${orderData.orderId}`,
      html: emailHtml,
    },
  });

  if (orderData.wantsSms === true) {
    const smsBody = buildSmsString(orderData);
    const smsRef = db.collection("sms_messages").doc();
    let phone = orderData.customerPhone.startsWith("+")
      ? orderData.customerPhone
      : "+64" + orderData.customerPhone.replace(/^0/, "");

    batch.set(smsRef, { to: phone, body: smsBody });
  }

  // --- OWNER EMAIL (instant) ---
  if (ownerEmail && ownerEmail.trim() !== "") {
    const ownerMailRef = db.collection("mail").doc();
    batch.set(ownerMailRef, {
      to: ownerEmail,
      message: {
        subject: `NEW ORDER #${orderData.orderId} - ${orderData.customerName}`,
        html: buildOwnerEmailHtml(orderData),
      },
    });
  }

  // Commit everything except the delayed owner SMS
  await batch.commit();

  // --- OWNER SMS (delayed) ---
  if (ownerPhone && ownerPhone.trim() !== "") {
    // Wait for the configured number of seconds
    await new Promise((resolve) => setTimeout(resolve, delaySeconds * 1000));

    const ownerSmsBody = buildOwnerSmsString(orderData);
    let formattedOwnerPhone = ownerPhone.startsWith("+")
      ? ownerPhone
      : "+64" + ownerPhone.replace(/^0/, "");

    await db.collection("sms_messages").add({
      to: formattedOwnerPhone,
      body: ownerSmsBody,
    });
  }

  return true;
}

module.exports = { processSuccessfulOrder };