import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const SEPAY_BASE_URL = "https://my.sepay.vn/userapi";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { endpoint, params, apiKey } = await req.json();

    if (!endpoint || !apiKey) {
      return new Response(
        JSON.stringify({ error: "Missing endpoint or apiKey" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build URL with query params
    const url = new URL(`${SEPAY_BASE_URL}/${endpoint}`);
    if (params && typeof params === "object") {
      for (const [key, value] of Object.entries(params)) {
        if (value !== null && value !== undefined) {
          url.searchParams.append(key, String(value));
        }
      }
    }

    console.log(`[PROXY] Forwarding to SePay: ${url.toString()}`);

    // Forward request to SePay
    const response = await fetch(url.toString(), {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    });

    const data = await response.json();
    console.log(`[PROXY] SePay response status: ${response.status}`);

    return new Response(JSON.stringify(data), {
      status: response.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[PROXY] Error:", err);
    return new Response(
      JSON.stringify({ error: `Proxy error: ${(err as Error).message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
