// 타입 보완(자동완성 도움)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/** ===== 공통 유틸 ===== */
function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}
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

/** ===== 환경변수 ===== */
const PROJECT_URL           = Deno.env.get("PROJECT_URL")!;
const SERVICE_ROLE_KEY      = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANDROID_PACKAGE_NAME  = Deno.env.get("ANDROID_PACKAGE_NAME")!;
const SA_B64                = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON_BASE64")!;
const EDGE_SECRET           = Deno.env.get("WONMORE_PUSH_SECRET")!;

// (iOS 폴백: 구 verifyReceipt)
const APPLE_SHARED_SECRET   = Deno.env.get("APPLE_SHARED_SECRET")!;

// (iOS 신식: App Store Server API)
const ASC_ISSUER_ID         = Deno.env.get("ASC_ISSUER_ID")!;
const ASC_KEY_ID            = Deno.env.get("ASC_KEY_ID")!;
const ASC_PRIVATE_KEY_P8    = Deno.env.get("ASC_PRIVATE_KEY_P8")!; // PEM 원문

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

/** 공통 응답 헬퍼 */
const res200 = (obj: unknown) =>
  new Response(JSON.stringify(obj), { status: 200, headers: { "Content-Type": "application/json" } });
const res400 = (msg: string) =>
  new Response(JSON.stringify({ ok: false, error: msg }), { status: 400, headers: { "Content-Type": "application/json" } });

/** ========= Android: OAuth2 ========= */
interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string; // RSA PKCS8 PEM
}
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
  // RSA 서명 준비
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
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const jwt = `${unsigned}.${sigB64}`;
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const j = await r.json();
  if (!j.access_token) throw new Error("Failed to get access token: " + JSON.stringify(j));
  return j.access_token as string;
}

/** ========= Android 상태 매핑 ========= */
function mapState(s?: string) {
  type S = "pending" | "active" | "canceled" | "expired" | "paused" | "past_due" | "unknown";
  let status: S = "unknown";
  let canceledPeriodEnd = false;
  switch (s) {
    case "SUBSCRIPTION_STATE_PENDING": status = "pending"; break;
    case "SUBSCRIPTION_STATE_ACTIVE": status = "active"; break;
    case "SUBSCRIPTION_STATE_PAUSED": status = "paused"; break;
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
    case "SUBSCRIPTION_STATE_ON_HOLD": status = "past_due"; break;
    case "SUBSCRIPTION_STATE_CANCELED": status = "canceled"; canceledPeriodEnd = true; break;
    case "SUBSCRIPTION_STATE_EXPIRED": status = "expired"; break;
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED": status = "canceled"; break;
    default: status = "unknown";
  }
  return { status, canceledPeriodEnd };
}

/** ========= iOS: App Store Server API 준비 ========= */
// p8 PEM → CryptoKey (ES256)
async function importAscP8Key(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\r|\n/g, "");
  const der = b64ToBytes(body);
  return await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}
// ASC JWT 생성
async function makeAscJwt(issuerId: string, keyId: string, key: CryptoKey): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = { iss: issuerId, iat: now, exp: now + 1800, aud: "appstoreconnect-v1" };
  const enc = (o: unknown) => btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  return `${unsigned}.${sigB64}`;
}
// iTunes verifyReceipt 폴백
const APPLE_PROD = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_SB   = "https://sandbox.itunes.apple.com/verifyReceipt";
async function callAppleReceipt(url: string, receipt: string, secret: string) {
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receipt,
      "password": secret,
      "exclude-old-transactions": true
    }),
  });
  return await r.json();
}

/** ========= 메인 ========= */
type VerifyPayload = {
  user_id: string;
  purchase_token?: string;   // 없으면 DB 최신 row 사용
  product_id?: string;
  is_sandbox?: boolean;
  store?: "google_play" | "apple_app_store";
};

Deno.serve(async (req) => {
  // 간단 인증
  if (!EDGE_SECRET || req.headers.get("x-api-key") !== EDGE_SECRET) {
    return res400("Unauthorized");
  }

  try {
    const body = (await req.json()) as VerifyPayload;
    const { user_id } = body;
    if (!user_id) return res400("user_id required");

    /** ================== iOS 분기 (StoreKit2 우선, 영수증 폴백) ================== */
    if (body.store === "apple_app_store") {
      let { purchase_token, product_id } = body;

      // 최신 row
      if (!purchase_token) {
        const r = await supa(`subscriptions?user_id=eq.${user_id}&store=eq.apple_app_store&order=created_at.desc&limit=1`);
        const rows = await r.json();
        if (!rows?.length) return res400("No iOS subscription row");
        purchase_token = rows[0].purchase_token;
        product_id = product_id ?? rows[0].product_id;
      }

      // 1) StoreKit2 JSON이면 → App Store Server API
      let otid: string | null = null;
      let env: "Sandbox" | "Production" = "Production";
      let isJson = false;
      if (purchase_token && purchase_token.trim().startsWith("{")) {
        isJson = true;
        try {
          const obj = JSON.parse(purchase_token);
          otid = obj.originalTransactionId || obj.original_transaction_id || obj.originalPurchaseId || null;
          env  = (obj.environment === "Sandbox") ? "Sandbox" : "Production";
          product_id = product_id ?? obj.productId ?? obj.product_id;
        } catch {
          // JSON 파싱 실패 시 폴백으로 내려감
        }
      }

      if (isJson && otid) {
        // === App Store Server API 호출 ===
        const key = await importAscP8Key(ASC_PRIVATE_KEY_P8);
        const jwt = await makeAscJwt(ASC_ISSUER_ID, ASC_KEY_ID, key);
        const host = env === "Sandbox"
          ? "https://api.storekit-sandbox.itunes.apple.com"
          : "https://api.storekit.itunes.apple.com";

        const resp = await fetch(`${host}/inApps/v1/subscriptions/${otid}`, {
          headers: { Authorization: `Bearer ${jwt}` }
        });
        const j = await resp.json();

        // 최신 트랜잭션 찾기 (productId 일치 우선)
        const candidates =
          (j?.data?.[0]?.lastTransactions ?? j?.data ?? [])
            .filter((x: any) => !product_id || x.productId === product_id);

        if (!Array.isArray(candidates) || candidates.length === 0) {
          await supa(
            `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
            { method: "PATCH", body: JSON.stringify({ status: "expired", last_verified_date: new Date().toISOString(), is_sandbox: env === "Sandbox" }) }
          );
          return res200({ ok: true, active: false });
        }

        candidates.sort((a: any, b: any) => Number(a.expiresDate ?? 0) - Number(b.expiresDate ?? 0));
        const latest = candidates[candidates.length - 1];

        const expiresMs = Number(latest.expiresDate ?? 0);
        const startMs   = Number(latest.signedDate ?? 0);
        const active    = expiresMs > Date.now();
        const canceled  = !!latest.revocationDate;

        const payload = {
          product_id: latest.productId,
          status: canceled ? "canceled" : (active ? "active" : "expired"),
          start_date: startMs ? new Date(startMs).toISOString() : null,
          end_date: new Date(expiresMs).toISOString(),
          last_verified_date: new Date().toISOString(),
          is_sandbox: env === "Sandbox",
        };

        const u = await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify(payload) }
        );
        if (!u.ok) {
          const t = await u.text();
          return new Response(JSON.stringify({ ok: false, source: "supabase", status: u.status, body: t }), { status: 500 });
        }
        return res200({ ok: true, active, isSandbox: env === "Sandbox" });
      }

      // 2) (폴백) base64 앱 영수증일 가능성 → verifyReceipt
      if (!purchase_token) return res400("no ios token");
      const looksBase64 = !purchase_token.trim().startsWith("{") && /^[A-Za-z0-9+/=\s]+$/.test(purchase_token.trim());
      if (!looksBase64) {
        // 영수증도 아니고 JSON도 아니면 검증 불가
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ last_verified_date: new Date().toISOString() }) }
        );
        return res200({ ok: false, error: "invalid ios token format" });
      }

      let resp = await callAppleReceipt(APPLE_PROD, purchase_token, APPLE_SHARED_SECRET);
      let isSandbox = false;
      if (resp?.status === 21007) {
        resp = await callAppleReceipt(APPLE_SB, purchase_token, APPLE_SHARED_SECRET);
        isSandbox = true;
      }
      if (resp?.status !== 0) {
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ status: "pending", last_verified_date: new Date().toISOString(), is_sandbox: isSandbox }) }
        );
        return res200({ ok: false, source: "apple", status: resp?.status });
      }

      const infos = Array.isArray(resp?.latest_receipt_info) ? resp.latest_receipt_info : [];
      const mine = infos.filter((it: any) => !product_id || it.product_id === product_id);
      if (!mine.length) {
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ status: "expired", last_verified_date: new Date().toISOString(), is_sandbox: isSandbox }) }
        );
        return res200({ ok: true, active: false });
      }
      mine.sort((a: any, b: any) => Number(a.expires_date_ms ?? 0) - Number(b.expires_date_ms ?? 0));
      const latest = mine[mine.length - 1];

      const expiresMs  = Number(latest.expires_date_ms ?? 0);
      const purchaseMs = Number(latest.original_purchase_date_ms ?? latest.purchase_date_ms ?? 0);
      const active     = expiresMs > Date.now();
      const canceled   = !!latest.cancellation_date_ms;

      const payload2 = {
        product_id: latest.product_id,
        status: canceled ? "canceled" : (active ? "active" : "expired"),
        start_date: new Date(purchaseMs).toISOString(),
        end_date: new Date(expiresMs).toISOString(),
        last_verified_date: new Date().toISOString(),
        is_sandbox: isSandbox,
      };
      const u2 = await supa(
        `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
        { method: "PATCH", body: JSON.stringify(payload2) }
      );
      if (!u2.ok) {
        const t = await u2.text();
        return new Response(JSON.stringify({ ok: false, source: "supabase", status: u2.status, body: t }), { status: 500 });
      }
      return res200({ ok: true, active, isSandbox });
    }

    /** ================== Android 분기 (기존 유지) ================== */
    const sa: ServiceAccount = JSON.parse(new TextDecoder().decode(b64ToBytes(SA_B64)));
    const accessToken = await getAccessToken(sa);

    let { purchase_token, product_id } = body;
    if (!purchase_token) {
      const r = await supa(`subscriptions?user_id=eq.${user_id}&store=eq.google_play&order=created_at.desc&limit=1`);
      const rows = await r.json();
      if (!rows?.length) return res400("No subscription row for user");
      purchase_token = rows[0].purchase_token;
      product_id = product_id ?? rows[0].product_id;
    }

    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchase_token!)}`;
    const gRes = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
    const gText = await gRes.text();

    if (!gRes.ok) {
      return new Response(JSON.stringify({ ok: false, source: "google", status: gRes.status, body: gText }), {
        status: 502, headers: { "Content-Type": "application/json" },
      });
    }

    const gp = JSON.parse(gText);
    const item = Array.isArray(gp?.lineItems) ? gp.lineItems[0] : undefined;
    const startIso = toIsoDate(item?.startTime ?? gp?.startTime);
    const endIso   = toIsoDate(item?.expiryTime ?? gp?.expiryTime);
    const { status, canceledPeriodEnd } = mapState(gp?.subscriptionState);
    const ackState = gp?.acknowledgementState;
    const isSandbox = !!gp?.testPurchase;

    const payload = {
      status,
      start_date: startIso,
      end_date: endIso,
      last_verified_date: new Date().toISOString(),
      canceled_date_period_end: canceledPeriodEnd,
      is_sandbox: isSandbox,
      product_id,
    };

    const pRes = await supa(
      `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
      { method: "PATCH", body: JSON.stringify(payload) }
    );
    const pText = await pRes.text();
    if (!pRes.ok) {
      return new Response(JSON.stringify({ ok: false, source: "supabase", status: pRes.status, body: pText }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

    return res200({
      ok: true,
      status,
      end_date: endIso,
      start_date: startIso,
      subscriptionState: gp?.subscriptionState,
      acknowledgementState: ackState,
      is_sandbox: isSandbox,
    });

  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
