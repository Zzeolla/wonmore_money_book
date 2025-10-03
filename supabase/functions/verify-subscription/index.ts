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

function toIsoDate(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "number") return new Date(v).toISOString();
  if (typeof v === "string") {
    const onlyDigits = /^\d+$/.test(v.trim());
    return new Date(onlyDigits ? parseInt(v, 10) : v).toISOString();
  }
  return null;
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
const EDGE_SECRET           = Deno.env.get("WONMORE_PUSH_SECRET")!; // 인증에 사용

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
  is_sandbox?: boolean;     // (선택) 클라이언트 힌트, 최종 판단은 Google 응답의 testPurchase 사용
  store?: "google_play";
};

/** 구글 상태 → 내부 상태 매핑 */
function mapState(s?: string) {
  type S = "pending" | "active" | "canceled" | "expired" | "paused" | "past_due" | "unknown";
  let status: S = "unknown";
  let canceledPeriodEnd = false;

  switch (s) {
    case "SUBSCRIPTION_STATE_PENDING":
      status = "pending"; break;
    case "SUBSCRIPTION_STATE_ACTIVE":
      status = "active"; break;
    case "SUBSCRIPTION_STATE_PAUSED":
      status = "paused"; break;
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
    case "SUBSCRIPTION_STATE_ON_HOLD":
      status = "past_due"; break; // 연체/보류 범주
    case "SUBSCRIPTION_STATE_CANCELED":
      status = "canceled"; canceledPeriodEnd = true; break; // 만료 전 해지
    case "SUBSCRIPTION_STATE_EXPIRED":
      status = "expired"; break;
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED":
      status = "canceled"; break; // 보류 결제 취소
    default:
      status = "unknown";
  }
  return { status, canceledPeriodEnd };
}

Deno.serve(async (req) => {
  // 간단 인증 (x-api-key)
  if (!EDGE_SECRET || req.headers.get("x-api-key") !== EDGE_SECRET) {
    return new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), {
      status: 401, headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body = (await req.json()) as VerifyPayload;

    // 서비스계정 로드(Base64 → JSON)
    const sa: ServiceAccount = JSON.parse(new TextDecoder().decode(b64ToBytes(SA_B64)));

    // 0) purchase_token 보정 (없으면 가장 최근 row)
    let { user_id, purchase_token, product_id } = body;
    if (!user_id) {
      return new Response(JSON.stringify({ ok: false, error: "user_id required" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }
    if (!purchase_token) {
      const r = await supa(`subscriptions?user_id=eq.${user_id}&order=created_at.desc&limit=1`);
      const rows = await r.json();
      if (!rows?.length) {
        return new Response(JSON.stringify({ ok: false, error: "No subscription row for user" }), {
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
      // 구글 실패시, 기존 pending 그대로 둘 수 있으니 에러 내용 반환
      return new Response(JSON.stringify({ ok: false, source: "google", status: gRes.status, body: gText }), {
        status: 502, headers: { "Content-Type": "application/json" },
      });
    }
    const gp = JSON.parse(gText);

    // 2) 상태/시간 파싱 (lineItems[0] 우선)
    const item = Array.isArray(gp?.lineItems) ? gp.lineItems[0] : undefined;

    const startIso = toIsoDate(item?.startTime ?? gp?.startTime);
    const endIso   = toIsoDate(item?.expiryTime ?? gp?.expiryTime);

    const { status, canceledPeriodEnd } = mapState(gp?.subscriptionState);
    const ackState = gp?.acknowledgementState; // 참고용
    const isSandbox = !!gp?.testPurchase;      // 테스트 구매 여부

    // 3) DB 갱신 (purchase_token 기준)
    const payload = {
      status,                               // 'pending'|'active'|'canceled'|'expired'|'paused'|'past_due'|'unknown'
      start_date: startIso,
      end_date: endIso,
      last_verified_date: new Date().toISOString(),
      canceled_date_period_end: canceledPeriodEnd,
      is_sandbox: isSandbox ?? false,                // 최종 판단은 Google 응답
      product_id,
      // acknowledgement_state: ackState,   // (원하면 컬럼 추가하여 저장)
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

    return new Response(JSON.stringify({
      ok: true,
      status,
      end_date: endIso,
      start_date: startIso,
      subscriptionState: gp?.subscriptionState,
      acknowledgementState: ackState,
      is_sandbox: isSandbox,
    }), {
      status: 200, headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
