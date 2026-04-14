import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

const localSynonyms: Record<string, string[]> = {
  mathi: ["sardine", "fresh sardine"],
  chala: ["sardine", "fresh sardine"],
  ayala: ["mackerel", "fresh mackerel"],
  chemmeen: ["prawns", "shrimp"],
  njandu: ["crab"],
  kappa: ["tapioca"],
  aval: ["rice flakes", "poha"],
  vellam: ["jaggery"],
  sharkkara: ["jaggery"],
  maida: ["plain flour"],
  atta: ["wheat flour", "chapati flour"],
  jeerakam: ["cumin"],
  perinjeerakam: ["fennel"],
  vendakka: ["okra"],
  cheera: ["spinach"],
  capsicum: ["bell pepper"],
};

function normalizeText(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[’']/g, "")
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function buildFallback(query: string) {
  const normalizedQuery = normalizeText(query);
  const aliasSet = new Set<string>();

  const addAlias = (value?: string) => {
    const normalized = normalizeText(value ?? "");
    if (!normalized || normalized === normalizedQuery) return;
    aliasSet.add(normalized);
  };

  for (const alias of localSynonyms[normalizedQuery] ?? []) {
    addAlias(alias);
  }

  for (const token of normalizedQuery.split(" ")) {
    for (const alias of localSynonyms[token] ?? []) {
      addAlias(alias);
    }
  }

  const aliases = Array.from(aliasSet);

  return {
    normalizedQuery,
    searchQuery: aliases[0] ?? normalizedQuery,
    aliases,
    source: "local",
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json().catch(() => ({}));
    const query = String(body.query ?? "").trim();

    if (!query) {
      return jsonResponse({ error: "Missing query" }, 400);
    }

    const fallback = buildFallback(query);
    const openAiKey = Deno.env.get("OPENAI_API_KEY");
    const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

    if (!openAiKey) {
      return jsonResponse(fallback);
    }

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "You normalize grocery search queries for a Kerala grocery app. Return strict JSON with keys searchQuery and aliases. searchQuery must be short plain-English product keywords that improve catalog search recall. Keep specific product names or brands when useful. aliases must be a short array of equivalent search phrases. Never include explanations.",
          },
          {
            role: "user",
            content: JSON.stringify({
              query,
              localFallback: fallback,
            }),
          },
        ],
      }),
    });

    if (!response.ok) {
      return jsonResponse(fallback);
    }

    const payload = await response.json();
    const content = payload?.choices?.[0]?.message?.content;
    const parsed = typeof content === "string" ? JSON.parse(content) : {};

    const aiSearchQuery = normalizeText(String(parsed.searchQuery ?? ""));
    const aiAliases = Array.isArray(parsed.aliases)
      ? parsed.aliases
          .map((value: unknown) => normalizeText(String(value ?? "")))
          .filter(Boolean)
      : [];

    const mergedAliases = Array.from(
      new Set([...fallback.aliases, ...aiAliases]),
    ).filter((value) => value && value !== aiSearchQuery);

    return jsonResponse({
      normalizedQuery: fallback.normalizedQuery,
      searchQuery: aiSearchQuery || fallback.searchQuery,
      aliases: mergedAliases,
      source: "openai",
    });
  } catch (_error) {
    return jsonResponse({ error: "Normalization failed" }, 500);
  }
});
