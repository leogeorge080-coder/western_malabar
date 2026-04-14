import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type OrderStatusEmailPayload = {
  email: string;
  customerName?: string;
  orderNumber: string;
  statusTitle: string;
  statusMessage: string;
};

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function buildEmailHtml(payload: OrderStatusEmailPayload): string {
  const hasCustomerName =
    typeof payload.customerName === "string" &&
    payload.customerName.trim().length > 0;

  const greeting = hasCustomerName
    ? `Hi ${escapeHtml(payload.customerName!.trim())},`
    : "Hi,";

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
            ${escapeHtml(payload.statusTitle)}
          </h2>

          <p style="margin:0 0 12px;color:#444;line-height:1.6;">
            ${greeting}
          </p>

          <p style="margin:0 0 18px;color:#444;line-height:1.6;">
            ${escapeHtml(payload.statusMessage)}
          </p>

          <div style="padding:18px;border-radius:14px;background:#fff9ee;border:1px solid #f0e2b6;">
            <div style="font-size:14px;color:#666;margin-bottom:6px;">Order number</div>
            <div style="font-size:22px;font-weight:700;color:#222;">#${escapeHtml(payload.orderNumber)}</div>
          </div>

          <p style="margin:28px 0 0;color:#555;line-height:1.6;">
            Thank you for choosing <strong>Malabar Hub</strong>.
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

    const body = await req.json() as Partial<OrderStatusEmailPayload>;

    if (!body.email || !body.orderNumber || !body.statusTitle || !body.statusMessage) {
      return new Response(
        JSON.stringify({
          error: "email, orderNumber, statusTitle, and statusMessage are required",
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

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Malabar Hub <orders@malabarhub.com>",
        to: [body.email],
        subject: `${body.statusTitle} • #${body.orderNumber}`,
        html: buildEmailHtml({
          email: body.email,
          customerName: body.customerName,
          orderNumber: body.orderNumber,
          statusTitle: body.statusTitle,
          statusMessage: body.statusMessage,
        }),
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