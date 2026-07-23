exports.buildSmsString = (orderData) => {
  let smsItemsString = "";
  
  if (orderData.items && Array.isArray(orderData.items)) {
    smsItemsString = orderData.items.map(item => {
      // Use short codes for extras to save space
      let extras = [];
      if (item.selectedSize) extras.push(item.selectedSize[0]); // 'L' instead of 'Large'
      if (item.selectedSpice) extras.push(item.selectedSpice);
      
      let extrasString = extras.length > 0 ? `(${extras.join(',')})` : "";
      return `${item.quantity}x ${item.name}${extrasString}`;
    }).join(", ");
  }
  
  let timeString = "ASAP";
  if (orderData.scheduledTimeEpoch) {
    const dateObj = new Date(orderData.scheduledTimeEpoch);
    // Use a shorter time format (e.g., 7:30 PM) to save space
    timeString = dateObj.toLocaleTimeString('en-NZ', { 
      timeZone: 'Pacific/Auckland', 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }

  // Extract just the first name to keep the SMS concise, fallback to 'there' if missing
  const firstName = orderData.customerName ? orderData.customerName.split(' ')[0] : 'there';

  // Return the updated string with the thank you and email notification
  return `Da Crust: Thanks ${firstName}! Order ${orderData.orderId} confirmed. Pickup: ${timeString}. Total: ${orderData.totalAmount}. Items: ${smsItemsString}. Details sent to your email.`;
};

// Add this below your existing buildSmsString function
exports.buildOwnerSmsString = (orderData) => {
  let smsItemsString = "";
  
  if (orderData.items && Array.isArray(orderData.items)) {
    smsItemsString = orderData.items.map(item => {
      let extras = [];
      if (item.selectedSize) extras.push(item.selectedSize[0]); // 'L'
      if (item.selectedSpice) extras.push(item.selectedSpice);
      let extrasString = extras.length > 0 ? `(${extras.join(',')})` : "";
      return `${item.quantity}x ${item.name}${extrasString}`;
    }).join(", ");
  }
  
  let timeString = "ASAP";
  if (orderData.scheduledTimeEpoch) {
    const dateObj = new Date(orderData.scheduledTimeEpoch);
    timeString = dateObj.toLocaleTimeString('en-NZ', { 
      timeZone: 'Pacific/Auckland', 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }

  // Packs Customer Name, Phone, Pickup Time, and Items into the SMS
  return `NEW ORDER: ${orderData.orderId}! Pickup: ${timeString}. Customer: ${orderData.customerName} (${orderData.customerPhone}). Items: ${smsItemsString}`;
};