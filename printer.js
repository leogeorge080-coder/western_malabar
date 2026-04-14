const escpos = require('escpos');
const USB = require('escpos-usb');
const QRCode = require('qrcode');
const { createCanvas, loadImage } = require('canvas');
const { createClient } = require('@supabase/supabase-js');

// ================= CONFIG =================
const SUPABASE_URL = 'YOUR_URL';
const SUPABASE_KEY = 'YOUR_SERVICE_ROLE_KEY';

// ================= INIT =================
escpos.USB = USB;
const device = new escpos.USB(); // auto-detect USB printer
const printer = new escpos.Printer(device);

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ================= LABEL GENERATOR =================
async function generateLabel(order) {
  const WIDTH = 812;
  const HEIGHT = 1218;

  const canvas = createCanvas(WIDTH, HEIGHT);
  const ctx = canvas.getContext('2d');

  // Background
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  ctx.fillStyle = '#000000';

  // ===== HEADER =====
  ctx.font = 'bold 48px Arial';
  ctx.fillText('WESTERN MALABAR', 30, 70);

  ctx.font = 'bold 40px Arial';
  ctx.fillText(`Order #${order.order_number}`, 30, 130);

  ctx.font = 'bold 30px Arial';
  ctx.fillText(order.payment_method || 'PAID', 600, 130);

  // ===== ADDRESS =====
  ctx.font = '34px Arial';
  ctx.fillText(order.customer_name || '', 30, 220);

  ctx.font = '30px Arial';
  ctx.fillText(order.phone || '', 30, 270);
  ctx.fillText(order.address_line1 || '', 30, 320);
  ctx.fillText(`${order.city || ''} ${order.postcode || ''}`.trim(), 30, 370);

  // ===== DELIVERY =====
  ctx.font = '28px Arial';
  ctx.fillText(order.delivery_slot || 'Delivery', 30, 430);

  if (order.has_frozen_items) {
    ctx.fillStyle = '#FF0000';
    ctx.font = 'bold 36px Arial';
    ctx.fillText('FROZEN', 30, 480);
    ctx.fillStyle = '#000000';
  }

  // ===== QR =====
  const qrText = `WM|ORDER|${order.id}|${order.order_number}`;

  // BIG QR
  const bigQR = await QRCode.toDataURL(qrText);
  const bigImg = await loadImage(bigQR);

  ctx.drawImage(bigImg, 156, 520, 500, 500);

  // SMALL QR (REPEATED)
  const smallQR = await QRCode.toDataURL(qrText);
  const smallImg = await loadImage(smallQR);

  ctx.drawImage(smallImg, 40, 1040, 180, 180);
  ctx.drawImage(smallImg, 316, 1040, 180, 180);
  ctx.drawImage(smallImg, 592, 1040, 180, 180);

  return canvas.toBuffer();
}

// ================= PRINT =================
async function printLabel(order) {
  const buffer = await generateLabel(order);

  return new Promise((resolve, reject) => {
    device.open((error) => {
      if (error) return reject(error);

      printer.align('ct').raster(buffer).cut().close();
      resolve();
    });
  });
}

// ================= POLLING =================
async function pollOrders() {
  const { data, error } = await supabase
    .from('orders')
    .select('*')
    .eq('qr_printed', false)
    .order('created_at', { ascending: true })
    .limit(5);

  if (error) {
    console.log('Fetch error:', error.message);
    return;
  }

  for (const order of data || []) {
    try {
      console.log('Printing:', order.order_number);

      await printLabel(order);

      await supabase.from('orders').update({ qr_printed: true }).eq('id', order.id);

      console.log('Printed ✓');
    } catch (e) {
      console.log('Print failed:', e.message || e);
    }
  }
}

// ================= START =================
console.log('🖨 Printer service started...');
setInterval(pollOrders, 5000);
pollOrders();
