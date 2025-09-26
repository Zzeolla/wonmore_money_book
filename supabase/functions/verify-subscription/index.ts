// 타입 보완(자동완성 도움)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/** Base64 → Uint8Array */
function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

/** 객체를 base64url 로 인코딩 (JWT용) */
function toBase64Url(obj: unknown): string {
  const json = JSON.stringify(obj);
  const b64 = btoa(json);
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string; // -----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----
}

/** SA로 OAuth2 access_token 발급 (scope: androidpublisher) */
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
    console.log('SA email:', sa.client_email);
    console.log('PKG:', ANDROID_PACKAGE_NAME);
  const headerB64 = toBase64Url(header);
  const payloadB64 = toBase64Url(payload);
  const unsigned = `${headerB64}.${payloadB64}`;

  // PEM → PKCS8 DER bytes
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\r|\n/g, "");
  const der = b64ToBytes(pem);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const jwt = `${unsigned}.${sigB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error("Failed to get access token: " + JSON.stringify(json));
  return json.access_token as string;
}

/** ========= 환경변수 ========= */
const PROJECT_URL           = Deno.env.get("PROJECT_URL")!;                 // https://<ref>.supabase.co
const SERVICE_ROLE_KEY      = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANDROID_PACKAGE_NAME  = Deno.env.get("ANDROID_PACKAGE_NAME")!;
const SA_B64                = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON_BASE64")!;

/** Supabase REST helper(Service Role로 호출) */
function supa(path: string, init?: RequestInit) {
  return fetch(`${PROJECT_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
      ...(init?.headers || {}),
    },
  });
}

/** 요청 바디 타입 */
type VerifyPayload = {
  user_id: string;
  purchase_token?: string;  // 없으면 DB에서 최신 row 찾아 사용
  product_id?: string;
  is_sandbox?: boolean;
  store?: "google_play";
};

Deno.serve(async (req) => {
  // 간단 인증 (x-api-key)
  const requiredKey = Deno.env.get("WONMORE_PUSH_SECRET"); // 기존 키 재사용
  if (!requiredKey || req.headers.get("x-api-key") !== requiredKey) {
    return new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), {
      status: 401, headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body = (await req.json()) as VerifyPayload;

    // 서비스계정 로드(Base64 → JSON)
    const sa: ServiceAccount = JSON.parse(new TextDecoder().decode(b64ToBytes(SA_B64)));

    // 0) purchase_token이 없으면 최신 구독 row에서 보충
    let { user_id, purchase_token, product_id } = body;
    if (!purchase_token) {
      const r = await supa(`subscriptions?user_id=eq.${user_id}&order=created_at.desc&limit=1`);
      const rows = await r.json();
      if (!rows?.length) {
        return new Response(JSON.stringify({ ok: false, error: "No subscription row" }), {
          status: 400, headers: { "Content-Type": "application/json" },
        });
      }
      purchase_token = rows[0].purchase_token;
      product_id = product_id ?? rows[0].product_id;
    }

    // 1) Google Play 검증 (subscriptionsv2)
    const accessToken = await getAccessToken(sa);
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchase_token!)}`;
    const gRes = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });

    const gText = await gRes.text();
    if (!gRes.ok) {
      return new Response(JSON.stringify({ ok: false, source: "google", status: gRes.status, body: gText }), {
        status: 502, headers: { "Content-Type": "application/json" },
      });
    }
    const gp = JSON.parse(gText);

    // 2) 상태/시간 파싱
    const lineItems = gp?.lineItems?.[0];
    const startMs  = lineItems?.startTime  ?? gp?.startTime;
    const expiryMs = lineItems?.expiryTime ?? gp?.expiryTime ?? gp?.latestOrder?.expiryTime;

    const startIso = startMs  ? new Date(Number(startMs)).toISOString()  : null;
    const endIso   = expiryMs ? new Date(Number(expiryMs)).toISOString() : null;

    const state = gp?.subscriptionState; // SUBSCRIPTION_STATE_ACTIVE / _CANCELED / _EXPIRED / _ON_HOLD / _IN_GRACE_PERIOD...
    let status = "pending";
    if (state === "SUBSCRIPTION_STATE_ACTIVE") status = "active";
    else if (state === "SUBSCRIPTION_STATE_CANCELED" || state === "SUBSCRIPTION_STATE_EXPIRED") status = "canceled";
    else if (state === "SUBSCRIPTION_STATE_ON_HOLD" || state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") status = "past_due";

    const canceledPeriodEnd = state === "SUBSCRIPTION_STATE_CANCELED";

    // 3) DB 갱신 (purchase_token 기준)
    const payload = {
      status,
      start_date: startIso,
      end_date: endIso,
      last_verified_date: new Date().toISOString(),
      canceled_date_period_end: canceledPeriodEnd,
      is_sandbox: body.is_sandbox ?? false,
      product_id,
    };

    const pRes = await supa(
      `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
      { method: "PATCH", body: JSON.stringify(payload) },
    );

    const pText = await pRes.text();
    if (!pRes.ok) {
      return new Response(JSON.stringify({ ok: false, source: "supabase", status: pRes.status, body: pText }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, status, end_date: endIso }), {
      status: 200, headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
