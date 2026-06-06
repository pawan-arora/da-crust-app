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

  // Keep the core info at the front
  return `Da Crust: Order #${orderData.orderId} confirmed! Pickup: ${timeString}. Total: $${orderData.totalAmount}. Items: ${smsItemsString}`;
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
  return `🚨 NEW ORDER #${orderData.orderId}! Pickup: ${timeString}. Customer: ${orderData.customerName} (${orderData.customerPhone}). Items: ${smsItemsString}`;
};