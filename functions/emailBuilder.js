exports.buildReceiptHtml = (orderData, restaurantData = {}) => {
  let itemsHtml = "";
  
  let trueSubtotal = 0;

  if (orderData.items && Array.isArray(orderData.items)) {
    orderData.items.forEach(item => {
      
      const itemPrice = Number(item.unitPriceAtAddition || item.price || 0);
      const itemTotal = itemPrice * Number(item.quantity || 1);
      trueSubtotal += itemTotal;

      let imageBlock = "";
      if (item.imagePath && item.imagePath.trim() !== "") {
        const safeUrl = item.imagePath.replace(/&/g, '&amp;');
        imageBlock = `<img src="${safeUrl}" width="60" height="60" style="border-radius: 8px; object-fit: cover;" alt="${item.name}" />`;
      } else {
        imageBlock = `
          <div style="width: 60px; height: 60px; background-color: #eeeeee; border-radius: 8px; text-align: center; line-height: 60px; font-size: 24px; color: #888888;">
            🍔
          </div>
        `;
      }
      
      // 🌟 NEW: Extract and format customization options
      let customizations = [];
      if (item.selectedSize) customizations.push(`Size: ${item.selectedSize}`);
      if (item.selectedSpice) customizations.push(`Spice: ${item.selectedSpice}`);
      
      let customizationHtml = "";
      if (customizations.length > 0) {
        customizationHtml = `<p style="margin: 4px 0 0 0; font-size: 13px; color: #ff5722; font-weight: 500;">${customizations.join(' | ')}</p>`;
      }
      
      itemsHtml += `
        <tr>
          <td style="padding: 15px 0; border-bottom: 1px solid #eeeeee; width: 60px;">
            ${imageBlock}
          </td>
          <td style="padding: 15px 10px; border-bottom: 1px solid #eeeeee;">
            <p style="margin: 0; font-weight: bold; font-size: 16px; color: #333333;">${item.name}</p>
            ${customizationHtml}
            <p style="margin: 4px 0 0 0; font-size: 14px; color: #777777;">Qty: ${item.quantity}</p>
          </td>
          <td style="padding: 15px 0; border-bottom: 1px solid #eeeeee; text-align: right; font-weight: bold; color: #333333;">
            $${itemTotal.toFixed(2)}
          </td>
        </tr>`;
    });
  }

  const total = Number(orderData.totalAmount);
  const gst = total - (total / 1.15); 
  const surcharge = Math.max(0, total - trueSubtotal); 

  let timeString = "ASAP";
  if (orderData.scheduledTimeEpoch) {
    const dateObj = new Date(orderData.scheduledTimeEpoch);
    timeString = dateObj.toLocaleString('en-NZ', { timeZone: 'Pacific/Auckland' });
  }

  const contact = restaurantData.contact || {};
  const restaurantName = contact.name || "Da Crust Pizzeria";
  const logoUrl = contact.logo || "";

  let headerBlockHtml = "";
  if (logoUrl) {
    const safeLogoUrl = logoUrl.replace(/&/g, '&amp;');
    headerBlockHtml = `<img src="${safeLogoUrl}" alt="${restaurantName}" style="max-height: 80px; max-width: 250px; object-fit: contain; margin-bottom: 10px;" />`;
  } else {
    headerBlockHtml = `<h1 style="color: #ff5722; margin: 0; font-size: 28px;">${restaurantName}</h1>`;
  }

  let surchargeRowHtml = "";
  if (surcharge > 0.01) { 
    surchargeRowHtml = `
      <tr>
        <td style="padding: 8px 0; color: #ff5722;">Card Surcharge (2%)</td>
        <td style="padding: 8px 0; text-align: right; color: #ff5722;">$${surcharge.toFixed(2)}</td>
      </tr>
    `;
  }

  return `
    <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
      
      <div style="text-align: center; margin-bottom: 30px;">
        ${headerBlockHtml}
        <p style="color: #777777; margin-top: 5px; font-size: 16px;">Order Confirmed</p>
      </div>

      <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
        <table width="100%" style="border-collapse: collapse;">
          <tr>
            <td style="padding-bottom: 10px;"><strong style="color: #333;">Order ID:</strong></td>
            <td style="padding-bottom: 10px; text-align: right; color: #555;">#${orderData.orderId}</td>
          </tr>
          <tr>
            <td style="padding-bottom: 10px;"><strong style="color: #333;">Pickup Time:</strong></td>
            <td style="padding-bottom: 10px; text-align: right; color: #555;">${timeString}</td>
          </tr>
          <tr>
            <td><strong style="color: #333;">Customer:</strong></td>
            <td style="text-align: right; color: #555;">${orderData.customerName}</td>
          </tr>
        </table>
      </div>

      <h3 style="color: #333333; margin-bottom: 15px; border-bottom: 2px solid #ff5722; padding-bottom: 8px; display: inline-block;">Order Summary</h3>
      
      <table width="100%" style="border-collapse: collapse; margin-bottom: 30px;">
        ${itemsHtml}
      </table>

      <table width="100%" style="border-collapse: collapse;">
        <tr>
          <td style="padding: 8px 0; color: #333333; font-weight: 500;">Subtotal</td>
          <td style="padding: 8px 0; text-align: right; color: #333333; font-weight: 500;">$${trueSubtotal.toFixed(2)}</td>
        </tr>
        
        ${surchargeRowHtml}
        
        <tr>
          <td style="padding: 4px 0 12px 0; color: #999999; font-size: 13px;">(Includes 15% GST)</td>
          <td style="padding: 4px 0 12px 0; text-align: right; color: #999999; font-size: 13px;">$${gst.toFixed(2)}</td>
        </tr>

        <tr>
          <td style="padding: 15px 0; font-size: 18px; font-weight: bold; color: #333333; border-top: 2px solid #eeeeee;">Total</td>
          <td style="padding: 15px 0; font-size: 18px; font-weight: bold; text-align: right; color: #ff5722; border-top: 2px solid #eeeeee;">$${total.toFixed(2)}</td>
        </tr>
      </table>

      <div style="margin-top: 40px; text-align: center; color: #888888; font-size: 14px;">
        <p>Thank you for choosing ${restaurantName}!</p>
        <p>Your food is being prepared by our kitchen.</p>
      </div>
    </div>
  `;
};