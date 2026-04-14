require('dotenv').config();

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const { createCanvas, loadImage } = require('canvas');
const escpos = require('escpos');
escpos.USB = require('escpos-usb');
const { print } = require('pdf-to-printer');
const { createClient } = require('@supabase/supabase-js');

const app = express();

const INTERNAL_API_TOKEN = (process.env.INTERNAL_API_TOKEN || '').trim();
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (ALLOWED_ORIGINS.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('CORS origin not allowed'));
    },
  })
);
app.use(express.json({ limit: '2mb' }));

const PORT = Number(process.env.PORT || 3000);
const BIND_HOST = (process.env.BIND_HOST || '127.0.0.1').trim();
const PRINT_DELAY_MS = 800;
const PRINT_POLL_MS = Number(process.env.PRINT_POLL_MS || 5000);
const PRINTER_NAME = (process.env.PRINTER_NAME || '').trim();

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !INTERNAL_API_TOKEN) {
  console.error(
    'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY or INTERNAL_API_TOKEN'
  );
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

const JOB_DIR = path.join(__dirname, 'print_jobs');
if (!fs.existsSync(JOB_DIR)) {
  fs.mkdirSync(JOB_DIR, { recursive: true });
}

let isPolling = false;
let lastPollAt = null;

function log(...args) {
  console.log(new Date().toISOString(), '-', ...args);
}

function requireInternalToken(req, res, next) {
  const token = req.header('x-internal-token');
  if (!token || token !== INTERNAL_API_TOKEN) {
    return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }
  next();
}

app.use((req, res, next) => {
  log('--- REQUEST START ---');
  log('Method:', req.method);
  log('URL:', req.originalUrl);
  next();
});

app.get('/', (req, res) => {
  res.send('Print server is running');
});

app.get('/health', requireInternalToken, async (req, res) => {
  try {
    const { count, error } = await supabase
      .from('print_jobs')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending');

    if (error) {
      throw error;
    }

    res.json({
      ok: true,
      pendingJobs: count || 0,
      isPolling,
      lastPollAt,
      printer: PRINTER_NAME || 'WINDOWS_DEFAULT',
    });
  } catch (e) {
    res.status(500).json({
      ok: false,
      error: e instanceof Error ? e.message : String(e),
      isPolling,
      lastPollAt,
    });
  }
});

app.get('/printers', requireInternalToken, async (req, res) => {
  exec(
    'powershell -Command "Get-Printer | Select-Object Name,DriverName,PortName | ConvertTo-Json -Depth 3"',
    (error, stdout, stderr) => {
      if (error) {
        console.error('PRINTER LIST ERROR:', error);
        return res.status(500).json({
          ok: false,
          error: error.toString(),
          stderr,
        });
      }

      try {
        const parsed = JSON.parse(stdout || '[]');
        const printers = Array.isArray(parsed) ? parsed : [parsed];
        return res.json({ ok: true, printers });
      } catch (e) {
        console.error('PRINTER LIST PARSE ERROR:', e);
        return res.status(500).json({
          ok: false,
          error: e.toString(),
          raw: stdout,
        });
      }
    }
  );
});

app.post('/print', requireInternalToken, async (req, res) => {
  try {
    const body = req.body || {};
    const order = normalizeManualOrder(body);

    if (!order.id || !order.order_number || !order.qr_code_value) {
      return res.status(400).json({
        ok: false,
        error: 'Missing required fields: orderId / orderNumber / qr',
      });
    }

    await printOrderWithSplit(order);

    return res.json({
      ok: true,
      message: 'Printed successfully',
    });
  } catch (e) {
    console.error('PRINT ERROR:', e);
    return res.status(500).json({
      ok: false,
      error: e instanceof Error ? e.message : String(e),
    });
  }
});

app.post('/poll-now', requireInternalToken, async (req, res) => {
  try {
    const processed = await pollAndProcessOnce();
    return res.json({
      ok: true,
      processed,
    });
  } catch (e) {
    return res.status(500).json({
      ok: false,
      error: e instanceof Error ? e.message : String(e),
    });
  }
});

function normalizeManualOrder(body) {
  return {
    id: body.orderId,
    order_number: body.orderNumber,
    qr_code_value: body.qr,
    customer_name: body.customerName || '',
    address_line1: body.addressLine1 || body.address || '',
    address_line2: body.addressLine2 || '',
    city: body.city || '',
    postcode: body.postcode || '',
    payment_method: body.paymentMethod || 'COD',
    delivery_slot: body.deliverySlot || 'Delivery',
    has_frozen_items: body.hasFrozenItems === true,
    has_normal_items:
      typeof body.hasNormalItems === 'boolean' ? body.hasNormalItems : !(
        body.hasFrozenItems === true
      ),
  };
}

function normalizeQueuedOrder(job) {
  const payload = job?.payload || {};

  return {
    id: payload.orderId || job.order_id || job.id,
    order_number: payload.orderNumber || job.order_number || '',
    qr_code_value: payload.qr || job.qr_code_value || '',
    customer_name: payload.customerName || '',
    address_line1: payload.addressLine1 || payload.address || '',
    address_line2: payload.addressLine2 || '',
    city: payload.city || '',
    postcode: payload.postcode || '',
    payment_method: payload.paymentMethod || 'COD',
    delivery_slot: payload.deliverySlot || 'Delivery',
    has_frozen_items: payload.hasFrozenItems === true,
    has_normal_items:
      typeof payload.hasNormalItems === 'boolean'
        ? payload.hasNormalItems
        : !(payload.hasFrozenItems === true),
  };
}

async function pollAndProcessOnce() {
  if (isPolling) {
    return false;
  }

  isPolling = true;
  lastPollAt = new Date().toISOString();

  try {
    const { data, error } = await supabase.rpc('reserve_next_print_job');

    if (error) {
      throw new Error(`reserve_next_print_job failed: ${error.message}`);
    }

    if (!data) {
      return false;
    }

    const job = data;
    const jobId = job.id;
    const order = normalizeQueuedOrder(job);

    log('Reserved print job:', jobId, order.order_number);

    try {
      await new Promise((resolve) => setTimeout(resolve, 5000));
      await printOrderWithSplit(order);

      const { error: printedError } = await supabase.rpc(
        'mark_print_job_printed',
        {
          p_job_id: jobId,
          p_printer_name: PRINTER_NAME || 'WINDOWS_DEFAULT',
        }
      );

      if (printedError) {
        throw new Error(
          `mark_print_job_printed failed: ${printedError.message}`
        );
      }

      log('Print job completed:', jobId, order.order_number);
      return true;
    } catch (printErr) {
      const errorText =
        printErr instanceof Error ? printErr.message : String(printErr);

      const { error: failedError } = await supabase.rpc(
        'mark_print_job_failed',
        {
          p_job_id: jobId,
          p_error: errorText,
          p_printer_name: PRINTER_NAME || 'WINDOWS_DEFAULT',
        }
      );

      if (failedError) {
        log('Failed to mark print job as failed:', failedError.message);
      }

      log('Print job failed:', jobId, errorText);
      return false;
    }
  } finally {
    isPolling = false;
  }
}

function startPolling() {
  setInterval(async () => {
    try {
      await pollAndProcessOnce();
    } catch (e) {
      log('Polling error:', e instanceof Error ? e.message : String(e));
    }
  }, PRINT_POLL_MS);

  log(`Supabase print polling started every ${PRINT_POLL_MS}ms`);
}

async function updateOrderPrintedLabelCount(orderId, count) {
  const { error } = await supabase
    .from('orders')
    .update({ printed_label_count: count })
    .eq('id', orderId);

  if (error) {
    console.error('Failed updating printed_label_count:', error);
  }
}

async function printOrderWithSplit(order) {
  const hasFrozen = order.has_frozen_items === true;
  const hasNormal = order.has_normal_items === true;

  if (hasFrozen && hasNormal) {
    await updateOrderPrintedLabelCount(order.id, 2);

    const normalLabel = {
      ...order,
      label_index: 1,
      total_labels: 2,
      suffix: 'N',
      is_frozen_label: false,
      type_text: 'NORMAL',
      zone_code: 'N',
    };

    const frozenLabel = {
      ...order,
      label_index: 2,
      total_labels: 2,
      suffix: 'F',
      is_frozen_label: true,
      type_text: 'FROZEN',
      zone_code: 'F',
    };

    const buffer1 = await generateLabel(normalLabel);
    await printBuffer(buffer1, normalLabel);

    await new Promise((resolve) => setTimeout(resolve, PRINT_DELAY_MS));

    const buffer2 = await generateLabel(frozenLabel);
    await printBuffer(buffer2, frozenLabel);
    return;
  }

  await updateOrderPrintedLabelCount(order.id, 1);

  if (hasFrozen) {
    const frozenOnlyLabel = {
      ...order,
      label_index: 1,
      total_labels: 1,
      suffix: 'F',
      is_frozen_label: true,
      type_text: 'FROZEN',
      zone_code: 'F',
    };

    const buffer = await generateLabel(frozenOnlyLabel);
    await printBuffer(buffer, frozenOnlyLabel);
    return;
  }

  const normalOnlyLabel = {
    ...order,
    label_index: 1,
    total_labels: 1,
    suffix: 'N',
    is_frozen_label: false,
    type_text: 'NORMAL',
    zone_code: 'N',
  };

  const buffer = await generateLabel(normalOnlyLabel);
  await printBuffer(buffer, normalOnlyLabel);
}

async function printBuffer(buffer, order) {
  try {
    await new Promise((resolve, reject) => {
      try {
        const device = new escpos.USB();
        const printer = new escpos.Printer(device);

        device.open((error) => {
          if (error) return reject(error);
          printer.align('ct').raster(buffer).cut().close(() => resolve());
        });
      } catch (error) {
        reject(error);
      }
    });

    log('ESC/POS print success:', order.order_number, order.suffix || '');
  } catch (error) {
    log(
      'ESC/POS print failed, falling back to Windows default printer:',
      error instanceof Error ? error.message : String(error)
    );
    await printBufferViaWindows(buffer, order);
  }
}

async function generateLabel(order) {
  const WIDTH = 812;
  const HEIGHT = 1218;

  const canvas = createCanvas(WIDTH, HEIGHT);
  const ctx = canvas.getContext('2d');

  const orderNumber = (order.order_number || '').toString().trim();
  const labelIndex = Number(order.label_index) || 1;
  const totalLabels = Number(order.total_labels) || 1;
  const suffix = (order.suffix || 'N').toString().trim().toUpperCase();
  const isFrozenLabel = order.is_frozen_label === true;

  const typeText = (
    order.type_text || (isFrozenLabel ? 'FROZEN' : 'NORMAL')
  )
    .toString()
    .trim()
    .toUpperCase();

  const zoneCode = (
    order.zone_code || (isFrozenLabel ? 'F' : 'N')
  )
    .toString()
    .trim()
    .toUpperCase();

  const displayOrderNumber = orderNumber
    ? `${orderNumber}-${suffix}`
    : suffix;

  const baseQrText = (
    order.qr_code_value || `WM|ORDER|${order.id}|${orderNumber}`
  )
    .toString()
    .trim();

  const qrText = `${baseQrText}-${suffix}`;

  const paymentRaw = (order.payment_method || '')
    .toString()
    .trim()
    .toUpperCase();

  const paymentText =
    paymentRaw === 'COD'
      ? 'COD'
      : paymentRaw === 'CARD'
      ? 'PAID'
      : paymentRaw || 'PAID';

  const customerName = (order.customer_name || '').toString().trim();
  const addressLine1 = (order.address_line1 || '').toString().trim();
  const addressLine2 = (order.address_line2 || '').toString().trim();
  const city = (order.city || '').toString().trim();
  const postcode = (order.postcode || '').toString().trim();
  const deliverySlot = (order.delivery_slot || 'Delivery').toString().trim();

  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  function line(x1, y1, x2, y2, width = 2, color = '#000000') {
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.lineWidth = width;
    ctx.strokeStyle = color;
    ctx.stroke();
  }

  function rect(x, y, w, h, fill = null, stroke = '#000000', lineWidth = 2) {
    if (fill) {
      ctx.fillStyle = fill;
      ctx.fillRect(x, y, w, h);
    }
    ctx.lineWidth = lineWidth;
    ctx.strokeStyle = stroke;
    ctx.strokeRect(x, y, w, h);
  }

  function fitText(
    text,
    x,
    y,
    maxWidth,
    font,
    color = '#000000',
    align = 'left'
  ) {
    let value = (text || '').toString();
    ctx.font = font;
    ctx.fillStyle = color;
    ctx.textAlign = align;

    while (value.length > 0 && ctx.measureText(value).width > maxWidth) {
      value = value.slice(0, -1);
    }

    if (value !== text && value.length > 3) {
      value = value.slice(0, -3) + '...';
    }

    ctx.fillText(value, x, y);
  }

  function wrapText(
    text,
    x,
    y,
    maxWidth,
    lineHeight,
    font,
    color = '#000000',
    maxLines = 3
  ) {
    const words = (text || '').toString().trim().split(/\s+/).filter(Boolean);
    if (!words.length) return y;

    ctx.font = font;
    ctx.fillStyle = color;
    ctx.textAlign = 'left';

    const lines = [];
    let current = '';

    for (const word of words) {
      const trial = current ? `${current} ${word}` : word;
      if (ctx.measureText(trial).width <= maxWidth) {
        current = trial;
      } else {
        if (current) lines.push(current);
        current = word;
      }
    }

    if (current) lines.push(current);

    const finalLines = lines.slice(0, maxLines);

    if (lines.length > maxLines) {
      let last = finalLines[finalLines.length - 1];
      while (last.length > 0 && ctx.measureText(`${last}...`).width > maxWidth) {
        last = last.slice(0, -1);
      }
      finalLines[finalLines.length - 1] = `${last}...`;
    }

    let cy = y;
    for (const l of finalLines) {
      ctx.fillText(l, x, cy);
      cy += lineHeight;
    }
    return cy;
  }

  // top strip
  ctx.fillStyle = '#000000';
  ctx.font = 'bold 22px Arial';
  ctx.textAlign = 'left';
  ctx.fillText('If undeliverable: return to store', 28, 42);

  rect(500, 18, 120, 54, '#FFFFFF');
  ctx.font = 'bold 18px Arial';
  ctx.fillStyle = '#000000';
  ctx.textAlign = 'center';
  ctx.fillText(`LABEL ${labelIndex}/${totalLabels}`, 560, 52);

  rect(630, 18, 150, 54, isFrozenLabel ? '#000000' : '#FFFFFF');
  ctx.font = 'bold 24px Arial';
  ctx.fillStyle = isFrozenLabel ? '#FFFFFF' : '#000000';
  ctx.fillText(typeText, 705, 52);

  // brand + header
  ctx.textAlign = 'left';
  ctx.fillStyle = '#000000';
  ctx.font = 'bold 30px Arial';
  ctx.fillText('MALABAR HUB', 28, 112);

  ctx.font = 'bold 24px Arial';
  fitText(`Order: ${displayOrderNumber}`, 28, 145, 720, 'bold 24px Arial');

  ctx.font = '22px Arial';
  fitText(deliverySlot, 28, 176, 520, '22px Arial', '#333333');

  line(28, 204, WIDTH - 28, 204, 2);

  // address block
  let y = 246;

  ctx.font = 'bold 32px Arial';
  fitText(customerName, 36, y, 620, 'bold 32px Arial');
  y += 42;

  y = wrapText(addressLine1, 36, y, 650, 38, '27px Arial', '#000000', 2);

  if (addressLine2) {
    y = wrapText(addressLine2, 36, y, 650, 38, '27px Arial', '#000000', 1);
  }

  const cityLine = [city, postcode].filter(Boolean).join(', ');
  y = wrapText(cityLine, 36, y, 700, 40, 'bold 28px Arial', '#000000', 2);

  // main QR section
  line(28, 470, WIDTH - 28, 470, 2);

  const bigQR = await QRCode.toDataURL(qrText, {
    errorCorrectionLevel: 'M',
    margin: 1,
    width: 280,
    color: { dark: '#000000', light: '#FFFFFF' },
  });
  const bigImg = await loadImage(bigQR);

  ctx.font = 'bold 34px Arial';
  ctx.textAlign = 'center';
  ctx.fillStyle = '#000000';
  fitText(
    displayOrderNumber,
    320,
    610,
    500,
    'bold 34px Arial',
    '#000000',
    'center'
  );

  ctx.drawImage(bigImg, 570, 500, 180, 180);

  // middle strip
  rect(28, 700, 390, 78, '#000000', '#000000', 2);
  rect(418, 700, 366, 78, '#FFFFFF', '#000000', 2);

  ctx.textAlign = 'center';
  ctx.font = 'bold 44px Arial';
  ctx.fillStyle = '#FFFFFF';
  ctx.fillText('MH', 223, 752);

  ctx.fillStyle = '#000000';
  ctx.fillText(paymentText, 601, 752);

  // lower section
  line(28, 846, WIDTH - 28, 846, 2);

  ctx.textAlign = 'left';
  ctx.font = 'bold 18px Arial';
  ctx.fillStyle = '#000000';
  ctx.fillText(`TYPE: ${typeText}`, 560, 878);

  const smallQR = await QRCode.toDataURL(qrText, {
    errorCorrectionLevel: 'M',
    margin: 1,
    width: 170,
    color: { dark: '#000000', light: '#FFFFFF' },
  });
  const smallImg = await loadImage(smallQR);

  ctx.drawImage(smallImg, 80, 910, 145, 145);
  ctx.drawImage(smallImg, 280, 910, 145, 145);
  ctx.drawImage(smallImg, 480, 910, 145, 145);

  // bottom right type box
  rect(640, 915, 120, 135, '#FFFFFF', '#000000', 2);
  ctx.textAlign = 'center';
  ctx.font = 'bold 92px Arial';
  ctx.fillStyle = '#000000';
  ctx.fillText(zoneCode, 700, 1008);

  // side refs
  ctx.save();
  ctx.translate(36, 1038);
  ctx.rotate(-Math.PI / 2);
  ctx.font = 'bold 20px Arial';
  ctx.fillText('MH4X6', 0, 0);
  ctx.restore();

  ctx.save();
  ctx.translate(790, 1038);
  ctx.rotate(-Math.PI / 2);
  ctx.font = 'bold 20px Arial';
  ctx.fillText('MH4X6', 0, 0);
  ctx.restore();

  // bottom left ops box
  rect(28, 1088, 160, 98, '#FFFFFF', '#000000', 2);

  ctx.textAlign = 'left';
  ctx.font = 'bold 34px Arial';
  ctx.fillStyle = '#000000';
  ctx.fillText('MH', 46, 1138);

  rect(46, 1148, 42, 28, '#000000', '#000000', 2);
  ctx.fillStyle = '#FFFFFF';
  ctx.font = 'bold 22px Arial';
  ctx.textAlign = 'center';
  ctx.fillText('B', 67, 1170);

  ctx.fillStyle = '#000000';
  ctx.textAlign = 'left';
  ctx.font = 'bold 36px Arial';
  ctx.fillText('001', 96, 1174);

  return canvas.toBuffer('image/png');
}

async function printBufferViaWindows(buffer, order) {
  const fileStem = [order.order_number || order.id, order.suffix || `L${order.label_index || 1}`]
    .filter(Boolean)
    .join('-');

  const pdfPath = path.join(JOB_DIR, `${sanitizeFileName(fileStem)}.pdf`);

  const doc = new PDFDocument({
    size: [288, 432],
    margin: 0,
  });

  const stream = fs.createWriteStream(pdfPath);
  doc.pipe(stream);
  doc.image(buffer, 0, 0, {
    fit: [288, 432],
    align: 'center',
    valign: 'center',
  });
  doc.end();

  await new Promise((resolve, reject) => {
    stream.on('finish', resolve);
    stream.on('error', reject);
  });

  const printOptions = {};
  if (PRINTER_NAME && PRINTER_NAME.length > 0) {
    printOptions.printer = PRINTER_NAME;
  }

  await print(pdfPath, printOptions);
  log('Windows fallback print success:', order.order_number);
}

function sanitizeFileName(name) {
  return String(name).replace(/[<>:"/\\|?*]+/g, '_');
}

app.listen(PORT, BIND_HOST, () => {
  log(`Print server running on port ${PORT}`);
  log(`Bind host: ${BIND_HOST}`);
  log(`Using printer: ${PRINTER_NAME || 'WINDOWS_DEFAULT'}`);
  startPolling();
});