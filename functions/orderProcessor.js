const admin = require("firebase-admin");
const { buildReceiptHtml } = require("./emailBuilder");
const { buildSmsString } = require("./smsBuilder");

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
  
  const batch = db.batch();

  batch.update(orderRef, {
    status: "PAID",
    paymentProvider: paymentProvider,
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const mailRef = db.collection("mail").doc();
  batch.set(mailRef, {
    to: orderData.customerEmail,
    message: { subject: `Da Crust Order Confirmed: #${orderData.orderId}`, html: emailHtml },
  });

  if (orderData.wantsSms === true) {
    const smsBody = buildSmsString(orderData);
    const smsRef = db.collection("sms_messages").doc();
    let phone = orderData.customerPhone.startsWith("+")
      ? orderData.customerPhone
      : "+64" + orderData.customerPhone.replace(/^0/, "");
    
    batch.set(smsRef, { to: phone, body: smsBody });
  }

  await batch.commit();
  return true;
}

module.exports = { processSuccessfulOrder };