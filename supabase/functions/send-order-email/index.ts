import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type OrderEmailPayload = {
  email: string;
  customerName?: string;
  orderNumber: string;
  totalCents: number;
  items?: Array<{
    name: string;
    qty: number;
    priceCents?: number;
  }>;
  deliveryType?: string;
  deliverySlot?: string;
};

function gbp(cents: number): string {
  return `£${(cents / 100).toFixed(2)}`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function buildItemsHtml(
  items: OrderEmailPayload["items"] = [],
): string {
  if (!items.length) return "";

  const rows = items
    .map((item) => {
      const lineTotal =
        typeof item.priceCents === "number"
          ? gbp(item.priceCents * item.qty)
          : "";
      return `
        <tr>
          <td style="padding:8px 0;color:#222;">${escapeHtml(item.name)}</td>
          <td style="padding:8px 0;color:#555;text-align:center;">${item.qty}</td>
          <td style="padding:8px 0;color:#222;text-align:right;">${lineTotal}</td>
        </tr>
      `;
    })
    .join("");

  return `
    <div style="margin-top:24px;">
      <h3 style="margin:0 0 12px;font-size:18px;color:#222;">Order items</h3>
      <table style="width:100%;border-collapse:collapse;">
        <thead>
          <tr>
            <th style="text-align:left;padding:8px 0;border-bottom:1px solid #eee;">Item</th>
            <th style="text-align:center;padding:8px 0;border-bottom:1px solid #eee;">Qty</th>
            <th style="text-align:right;padding:8px 0;border-bottom:1px solid #eee;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${rows}
        </tbody>
      </table>
    </div>
  `;
}

function buildEmailHtml(payload: OrderEmailPayload): string {
  const {
    customerName,
    orderNumber,
    totalCents,
    items,
    deliveryType,
    deliverySlot,
  } = payload;

  const greeting = customerName
    ? `Hi ${escapeHtml(customerName)},`
    : "Hi,";

  const deliveryHtml =
    deliveryType || deliverySlot
      ? `
      <div style="margin-top:20px;padding:16px;border-radius:12px;background:#faf7ff;border:1px solid #eee;">
        <div style="font-weight:600;font-size:16px;margin-bottom:8px;color:#222;">Delivery details</div>
        ${
          deliveryType
            ? `<div style="color:#555;margin-bottom:6px;">Type: ${escapeHtml(deliveryType)}</div>`
            : ""
        }
        ${
          deliverySlot
            ? `<div style="color:#555;">Slot: ${escapeHtml(deliverySlot)}</div>`
            : ""
        }
      </div>
    `
      : "";

  return `
    <div style="margin:0;padding:0;background:#f6f6f8;font-family:Arial,sans-serif;">
      <div style="max-width:640px;margin:0 auto;padding:24px;">
        <div style="background:#ffffff;border-radius:18px;padding:32px;border:1px solid #ececec;">
          <div style="font-size:28px;font-weight:700;color:#5A2D82;margin-bottom:8px;">
            Malabar Hub
          </div>
          <div style="font-size:14px;color:#777;margin-bottom:24px;">
            South Indian groceries delivered with care
          </div>

          <h2 style="margin:0 0 16px;font-size:24px;color:#222;">
            Order confirmed
          </h2>

          <p style="margin:0 0 12px;color:#444;line-height:1.6;">
            ${greeting}
          </p>

          <p style="margin:0 0 18px;color:#444;line-height:1.6;">
            Thank you for your order. We’ve received it successfully and will start processing it soon.
          </p>

          <div style="padding:18px;border-radius:14px;background:#fff9ee;border:1px solid #f0e2b6;">
            <div style="font-size:14px;color:#666;margin-bottom:6px;">Order number</div>
            <div style="font-size:22px;font-weight:700;color:#222;">#${escapeHtml(orderNumber)}</div>
            <div style="font-size:14px;color:#666;margin-top:14px;">Order total</div>
            <div style="font-size:24px;font-weight:700;color:#222;">${gbp(totalCents)}</div>
          </div>

          ${buildItemsHtml(items)}
          ${deliveryHtml}

          <p style="margin:28px 0 0;color:#555;line-height:1.6;">
            We’ll keep you updated as your order moves forward.
          </p>

          <p style="margin:16px 0 0;color:#555;line-height:1.6;">
            Regards,<br />
            <strong>Malabar Hub</strong>
          </p>
        </div>
      </div>
    </div>
  `;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: "Missing RESEND_API_KEY secret" }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const body = (await req.json()) as Partial<OrderEmailPayload>;

    if (!body.email || !body.orderNumber || typeof body.totalCents !== "number") {
      return new Response(
        JSON.stringify({
          error: "email, orderNumber, and totalCents are required",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const payload: OrderEmailPayload = {
      email: body.email,
      customerName: body.customerName,
      orderNumber: body.orderNumber,
      totalCents: body.totalCents,
      items: body.items ?? [],
      deliveryType: body.deliveryType,
      deliverySlot: body.deliverySlot,
    };

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Malabar Hub <orders@malabarhub.com>",
        to: [payload.email],
        subject: `Order Confirmed • #${payload.orderNumber}`,
        html: buildEmailHtml(payload),
      }),
    });

    const resendData = await resendResponse.json();

    if (!resendResponse.ok) {
      return new Response(
        JSON.stringify({
          error: "Resend request failed",
          details: resendData,
        }),
        {
          status: 502,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        resend: resendData,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});