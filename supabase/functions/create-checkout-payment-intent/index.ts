import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";

type CartItemInput = {
  product_id?: string;
  qty?: number;
};

type ProductRow = {
  id: string;
  is_active: boolean;
  is_available: boolean;
  is_frozen: boolean | null;
  price_cents: number | null;
  is_weekly_deal: boolean | null;
  deal_price_cents: number | null;
  deal_starts_at: string | null;
  deal_ends_at: string | null;
  stock_qty: number | null;
  available_qty: number | null;
  name?: string | null;
};

const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
if (!stripeSecretKey) {
  throw new Error("Missing STRIPE_SECRET_KEY");
}

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: "2023-10-16",
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

function isActiveDeal(product: ProductRow): boolean {
  if (
    product.is_weekly_deal !== true ||
    product.deal_price_cents == null ||
    product.deal_starts_at == null ||
    product.deal_ends_at == null
  ) {
    return false;
  }

  const now = Date.now();
  const start = new Date(product.deal_starts_at).getTime();
  const end = new Date(product.deal_ends_at).getTime();

  if (Number.isNaN(start) || Number.isNaN(end)) return false;
  return now >= start && now <= end;
}

function finalPriceCents(product: ProductRow): number {
  if (isActiveDeal(product)) {
    return Number(product.deal_price_cents ?? 0);
  }
  return Number(product.price_cents ?? 0);
}

async function fetchAuthenticatedUser(
  supabaseUrl: string,
  supabaseAnonKey: string,
  authHeader: string,
) {
  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: supabaseAnonKey,
    },
  });

  if (!userRes.ok) {
    const userText = await userRes.text();
    throw new Error(`Failed to fetch authenticated user: ${userText}`);
  }

  const user = await userRes.json();
  if (!user?.id) {
    throw new Error("Unauthorized user");
  }

  return user;
}

async function fetchRewardPoints(
  supabaseUrl: string,
  supabaseAnonKey: string,
  authHeader: string,
  userId: string,
): Promise<number> {
  const rewardRes = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}&select=reward_points`,
    {
      headers: {
        Authorization: authHeader,
        apikey: supabaseAnonKey,
      },
    },
  );

  if (!rewardRes.ok) {
    const rewardText = await rewardRes.text();
    throw new Error(`Failed to fetch reward points: ${rewardText}`);
  }

  const rewardData = await rewardRes.json();
  return Number(rewardData?.[0]?.reward_points ?? 0);
}

async function fetchProductsByIds(
  supabaseUrl: string,
  supabaseAnonKey: string,
  authHeader: string,
  productIds: string[],
): Promise<Map<string, ProductRow>> {
  const uniqueIds = [...new Set(productIds)];
  if (uniqueIds.length === 0) {
    throw new Error("Cart is empty");
  }

  const inList = uniqueIds.map((id) => `"${id}"`).join(",");
  const url =
    `${supabaseUrl}/rest/v1/products` +
    `?select=id,name,is_active,is_available,is_frozen,price_cents,is_weekly_deal,deal_price_cents,deal_starts_at,deal_ends_at,stock_qty,available_qty` +
    `&id=in.(${encodeURIComponent(inList)})`;

  const res = await fetch(url, {
    headers: {
      Authorization: authHeader,
      apikey: supabaseAnonKey,
    },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to fetch products: ${text}`);
  }

  const rows = (await res.json()) as ProductRow[];
  const byId = new Map<string, ProductRow>();

  for (const row of rows) {
    byId.set(row.id, row);
  }

  return byId;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error("Missing required environment variables");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }

    const user = await fetchAuthenticatedUser(
      supabaseUrl,
      supabaseAnonKey,
      authHeader,
    );

    const body = await req.json();
    const cartItems = body?.cart_items as CartItemInput[] | undefined;
    const deliveryType = body?.delivery_type;
    const useRewards = body?.use_rewards === true;

    if (!Array.isArray(cartItems) || cartItems.length === 0) {
      throw new Error("Cart is empty");
    }

    if (
      deliveryType !== "home_delivery" &&
      deliveryType !== "local_pickup"
    ) {
      throw new Error("Invalid delivery type");
    }

    const productIds = cartItems.map((item) => String(item?.product_id ?? ""));
    const productsById = await fetchProductsByIds(
      supabaseUrl,
      supabaseAnonKey,
      authHeader,
      productIds,
    );

    let subtotal = 0;
    let eligibleSubtotal = 0;

    for (const item of cartItems) {
      const productId = String(item?.product_id ?? "").trim();
      const qty = Number(item?.qty ?? 0);

      if (!productId) {
        throw new Error("Missing product_id");
      }

      if (!Number.isInteger(qty) || qty <= 0) {
        throw new Error("Invalid cart quantity");
      }

      const product = productsById.get(productId);
      if (!product) {
        throw new Error(`Invalid product in cart: ${productId}`);
      }

      if (product.is_active !== true) {
        throw new Error(`Inactive product in cart: ${product.name ?? productId}`);
      }

      if (product.is_available !== true) {
        throw new Error(`Unavailable product in cart: ${product.name ?? productId}`);
      }

      const unit = finalPriceCents(product);
      if (!Number.isInteger(unit) || unit <= 0) {
        throw new Error(`Invalid product price for: ${product.name ?? productId}`);
      }

      if (
        product.stock_qty != null &&
        product.stock_qty >= 0 &&
        qty > product.stock_qty
      ) {
        throw new Error(`Insufficient stock for: ${product.name ?? productId}`);
      }

      if (
        product.available_qty != null &&
        product.available_qty >= 0 &&
        qty > product.available_qty
      ) {
        throw new Error(
          `Insufficient available quantity for: ${product.name ?? productId}`,
        );
      }

      const line = unit * qty;
      subtotal += line;

      if (product.is_frozen !== true) {
        eligibleSubtotal += line;
      }
    }

    const deliveryFee =
      deliveryType === "home_delivery"
        ? subtotal >= 2000
          ? 0
          : 250
        : 0;

    let rewardDiscount = 0;
    let pointsToRedeem = 0;

    if (useRewards) {
      const points = await fetchRewardPoints(
        supabaseUrl,
        supabaseAnonKey,
        authHeader,
        user.id,
      );

      const pointsPerBlock = 200;
      const blockValue = 200;

      const blocks = Math.floor(points / pointsPerBlock);
      const maxReward = blocks * blockValue;

      rewardDiscount = Math.min(maxReward, eligibleSubtotal);
      pointsToRedeem =
        Math.floor(rewardDiscount / blockValue) * pointsPerBlock;
    }

    const total = subtotal - rewardDiscount + deliveryFee;

    if (!Number.isInteger(total) || total < 0) {
      throw new Error("Invalid total calculation");
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: total,
      currency: "gbp",
      automatic_payment_methods: { enabled: true },
      metadata: {
        user_id: String(user.id),
        reward_discount_cents: String(rewardDiscount),
        points_to_redeem: String(pointsToRedeem),
      },
    });

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        subtotal_cents: subtotal,
        eligible_subtotal_cents: eligibleSubtotal,
        delivery_fee_cents: deliveryFee,
        reward_discount_cents: rewardDiscount,
        points_to_redeem: pointsToRedeem,
        total_cents: total,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);

    return new Response(
      JSON.stringify({ error: message }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});