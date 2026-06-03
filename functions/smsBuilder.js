exports.buildSmsString = (orderData) => {
  let smsItemsString = "";
  
  if (orderData.items && Array.isArray(orderData.items)) {
    // 🌟 NEW: Map through items and dynamically append options if they exist
    smsItemsString = orderData.items.map(item => {
      let extras = [];
      if (item.selectedSize) extras.push(item.selectedSize);
      if (item.selectedSpice) extras.push(item.selectedSpice);
      
      // If there are extras, wrap them in parentheses, otherwise leave blank
      let extrasString = extras.length > 0 ? ` (${extras.join(', ')})` : "";
      
      return `${item.quantity}x ${item.name}${extrasString}`;
    }).join(", ");
  }
  
  let timeString = "ASAP";
  if (orderData.scheduledTimeEpoch) {
    const dateObj = new Date(orderData.scheduledTimeEpoch);
    timeString = dateObj.toLocaleString('en-NZ', { timeZone: 'Pacific/Auckland' });
  }

  return `Da Crust: Order #${orderData.orderId} confirmed! Items: ${smsItemsString}. Total: $${orderData.totalAmount}. Pickup: ${timeString}`;
};