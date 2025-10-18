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
const ASC_ISSUER_ID         = (Deno.env.get("ASC_ISSUER_ID") ?? "").trim().replace(/^"+|"+$/g, "");
const ASC_KEY_ID            = (Deno.env.get("ASC_KEY_ID") ?? "").trim().replace(/^"+|"+$/g, "");
const IOS_BUNDLE_ID         = (Deno.env.get("IOS_BUNDLE_ID") ?? "").trim().replace(/^"+|"+$/g, "");
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
  const payload = { iss: issuerId, iat: now - 5, exp: now + 1200, aud: "appstoreconnect-v1" };
  const enc = (o: unknown) => btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  return `${unsigned}.${sigB64}`;
}

// ====== ASC JWT 생성(수정판) ======
async function makeAscJwtWithBid(issuerId: string, keyId: string, key: CryptoKey, bundleId: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = {
    iss: issuerId,
    iat: now - 5,
    exp: now + 1200,             // 30분 유효
    aud: "appstoreconnect-v1",
    bid: bundleId,               // <<< 반드시 포함
  };
  const enc = (o: unknown) => btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  return `${unsigned}.${sigB64}`;
}

// ====== ASC 호출 헬퍼 (프로덕션 -> 샌드박스 자동 재시도) ======
async function callAscSubscriptions(otid: string, jwt: string) {
  const PROD = "https://api.storekit.itunes.apple.com";
  const SB   = "https://api.storekit-sandbox.itunes.apple.com";

  // subscriptions 조회 시도 (Prod -> Sandbox 재시도)
  async function trySub(base: string) {
    const url = `${base}/inApps/v1/subscriptions/${encodeURIComponent(otid)}`;
    const r = await fetch(url, { headers: { Authorization: `Bearer ${jwt}` } });
    const txt = await r.text();
    // r.ok일 경우 JSON 반환, 401이면 throw with status
    if (!r.ok) {
      const st = r.status;
      const err = new Error(`ASC subscriptions ${st}: ${txt}`);
      (err as any).status = st;
      throw err;
    }
    return JSON.parse(txt);
  }

  try {
    return { data: await trySub(PROD), sandbox: false };
  } catch (e) {
    // ✅ 상태코드 무관, 샌드박스도 시도 (401 포함)
    try {
      return { data: await trySub(SB), sandbox: true };
    } catch (e2) {
      throw e;
    }
  }
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

function normalizeP8(pem: string) {
  // 1) 리터럴 \n → 실제 개행
  const withRealNL = pem.includes("\\n") ? pem.replace(/\\n/g, "\n") : pem;
  // 2) 앞뒤 공백/따옴표 제거
  return withRealNL.trim().replace(/^"+|"+$/g, "");
}

async function testAscJwtConnectivity(jwt: string) {
  const url = "https://api.appstoreconnect.apple.com/v1/apps?limit=1";
  const r = await fetch(url, { headers: { Authorization: `Bearer ${jwt}` } });
  return { ok: r.ok, status: r.status, body: await r.text() };
}

function decodeBase64UrlToJson(b64u: string) {
  const pad = b64u.replace(/-/g, "+").replace(/_/g, "/");
  const json = atob(pad + "=".repeat((4 - (pad.length % 4)) % 4));
  return JSON.parse(json);
}
function decodeJwsPayload(jws: string) {
  const parts = jws.split(".");
  if (parts.length < 2) throw new Error("invalid JWS");
  return decodeBase64UrlToJson(parts[1]); // payload
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

    // ====== iOS 분기: ASC -> (401 -> verifyReceipt 폴백) 흐름 예시 ======
    if (body.store === "apple_app_store") {
      // (purchase_token 확보 로직은 기존 코드와 동일)
      // purchase_token은 StoreKit2 JSON string OR base64 receipt
      // 이미 있으면 사용, 없으면 DB에서 최신 row를 읽음
      let { purchase_token, product_id } = body;
      if (!purchase_token) {
        const r = await supa(`subscriptions?user_id=eq.${user_id}&store=eq.apple_app_store&order=created_at.desc&limit=1`);
        const rows = await r.json();
        if (!rows?.length) return res400("No iOS subscription row");
        purchase_token = rows[0].purchase_token;
        product_id = product_id ?? rows[0].product_id;
      }

      // 0) 토큰 형태 판단: JSON(StoreKit2)인지 base64(verifyReceipt)인지
      let tokenLooksJson = false;
      let otid: string | null = null;
      if (purchase_token && purchase_token.trim().startsWith("{")) {
        tokenLooksJson = true;
        try {
          const obj = JSON.parse(purchase_token);
          otid = String(obj.originalTransactionId ?? obj.original_transaction_id ?? "").trim();
          if (!/^\d+$/.test(otid)) {
            return res200({ ok:false, error:"invalid otid", sample: obj.originalTransactionId ?? obj.original_transaction_id });
          }
          product_id = product_id ?? obj.productId ?? obj.product_id;
        } catch {
          tokenLooksJson = false;
        }
      }

      // 1) StoreKit2 JSON 경로 -> ASC 호출 (정상 루트)
      if (tokenLooksJson && otid) {
        try {
          const ascKeyPem = normalizeP8(ASC_PRIVATE_KEY_P8);
          const ascKey = await importAscP8Key(ascKeyPem);
          const jwt = await makeAscJwtWithBid(ASC_ISSUER_ID, ASC_KEY_ID, ascKey, IOS_BUNDLE_ID);

          // 사용 예 (디버그용; bid 없는 JWT로 만드세요)
          const jwtNoBid = await makeAscJwt(ASC_ISSUER_ID, ASC_KEY_ID, ascKey);
          const probe = await testAscJwtConnectivity(jwtNoBid);
          // return res200({ ok:false, probe }); // 임시로 확인

          // jwt 생성 직후, payload 디코드해 확인(디버깅용)
          function decodeJwtPayload(jwt: string) {
            const part = jwt.split(".")[1];
            const pad = part.replace(/-/g, "+").replace(/_/g, "/");
            const json = atob(pad + "=".repeat((4 - (pad.length % 4)) % 4));
            return JSON.parse(json);
          }

          function decodeJwtHeader(jwt: string) {
            const part = jwt.split(".")[0];
            const pad = part.replace(/-/g, "+").replace(/_/g, "/");
            const json = atob(pad + "=".repeat((4 - (pad.length % 4)) % 4));
            return JSON.parse(json);
          }

          function decodeJwtParts(jwt: string) {
            const dec = (s: string) => atob(s.replace(/-/g,"+").replace(/_/g,"/") + "=".repeat((4-(s.length%4))%4));
            const [h,p] = jwt.split(".");
            return { header: JSON.parse(dec(h)), claims: JSON.parse(dec(p)) };
          }
          // jwt 만들고 바로 아래
//           const { header, claims } = decode(jwt);
//           return res200({ ok:false, debug: { kid_env: Deno.env.get("ASC_KEY_ID"), header, claims } });
//
//           const header = decodeJwtHeader(jwt);
//
//           // 디버깅: 실제 들어간 클레임 확인 (배포 후 호출해서 값 확인하고, 나중에 제거)
//           const claims = decodeJwtPayload(jwt);
//           // return res200({ ok:false, debug: { header, claims } }); // ← 임시로 열고 확인해도 됨

          // ── 여기만 임시 디버그 ──
          const decode = (s:string)=>atob(s.replace(/-/g,"+").replace(/_/g,"/")+"=".repeat((4-(s.length%4))%4));
          const [h,p] = jwt.split(".");
          const header = JSON.parse(decode(h));
          const claims = JSON.parse(decode(p));
          // return res200({ ok:false, debug: { kid_env: Deno.env.get("ASC_KEY_ID"), header, claims } });
          // ───────────────────────

          const ascResp = await callAscSubscriptions(otid, jwt); // may throw 401
          const j = ascResp.data;

          // candidates 추출(기존 로직)
          let candidates: any[] = [];

          // 1) v1/subscriptions 표준 응답: data[0].lastTransactions[*].signedTransactionInfo (JWS)
          const dataArr = Array.isArray(j?.data) ? j.data : [];
          if (dataArr.length && Array.isArray(dataArr[0]?.lastTransactions)) {
            for (const t of dataArr[0].lastTransactions) {
              const jws = t?.signedTransactionInfo || t?.signedRenewalInfo; // 보통 signedTransactionInfo
              if (typeof jws === "string") {
                try {
                  const payload = decodeJwsPayload(jws);
                  candidates.push(payload);
                } catch {/* ignore bad token */}
              }
            }
          }

          // 2) 혹시 signedTransactions 배열만 있는 케이스(JWS 배열)
          if (!candidates.length && Array.isArray(j?.signedTransactions)) {
            for (const jws of j.signedTransactions) {
              if (typeof jws === "string") {
                try { candidates.push(decodeJwsPayload(jws)); } catch {/* ignore */}
              }
            }
          }

          // 3) 그래도 없으면 (비표준/중간형) data 자체에 평문이 있는지 마지막 확인
          if (!candidates.length && dataArr.length) {
            // 극히 드뭄: 일부 프록시/도큐 버전에서 평문 필드가 올 수도 있어 방어적으로
            candidates = dataArr;
          }

          if (product_id) {
            candidates = candidates.filter((x: any) => x.productId === product_id || x.product_id === product_id);
          }

          // 없으면 pending 업데이트
          if (!candidates.length) {
            await supa(
              `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
              { method: "PATCH", body: JSON.stringify({ status: "pending", last_verified_date: new Date().toISOString(), is_sandbox: ascResp.sandbox }) }
            );
            return res200({ ok: false, reason: "no-candidates", sandbox: ascResp.sandbox });
          }

          // 정렬 및 최신 선택 (StoreKit2 JWS payload 기준: 밀리초 혹은 초 단위가 혼재 가능)
          function toMs(v: any) {
            const n = Number(v ?? 0);
            // 10자리면 초, 13자리면 밀리초로 간주
            if (n > 0 && n < 1e12) return n * 1000;
            return n;
          }
          candidates.sort((a: any, b: any) => toMs(a.expiresDate ?? a.expires_date_ms) - toMs(b.expiresDate ?? b.expires_date_ms));
          const latest = candidates[candidates.length - 1];

          const expiresMs = toMs(latest.expiresDate ?? latest.expires_date_ms);
          const startMs   = toMs(latest.signedDate ?? latest.originalPurchaseDate ?? latest.original_purchase_date_ms ?? latest.purchaseDate ?? latest.purchase_date_ms);
          const active    = expiresMs > Date.now();
          const canceled  = !!(latest.revocationDate || latest.cancellation_date_ms || latest.revocationReason);

          // DB 업데이트 payload
          const payload = {
            product_id: latest.productId ?? latest.product_id ?? product_id,
            status: canceled ? "canceled" : (active ? "active" : "expired"),
            start_date: startMs ? new Date(startMs).toISOString() : null,
            end_date: expiresMs ? new Date(expiresMs).toISOString() : null,
            last_verified_date: new Date().toISOString(),
            is_sandbox: ascResp.sandbox,
          };

          const u = await supa(
            `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
            { method: "PATCH", body: JSON.stringify(payload) }
          );
          if (!u.ok) {
            const t = await u.text();
            return new Response(JSON.stringify({ ok: false, source: "supabase", status: u.status, body: t }), { status: 500, headers: { "Content-Type": "application/json" } });
          }
          return res200({ ok: true, active, sandbox: ascResp.sandbox });
        } catch (err: any) {
          // ASC가 왜 죽는지 그대로 알려주고 종료 (폴백은 base64 있을 때만)
          return res200({
            ok: false,
            source: "asc",
            error: String(err),
          });
        }
      }

      // 2) 폴백: verifyReceipt (base64 영수증 필요)
      const looksBase64 = !!purchase_token && !purchase_token.trim().startsWith("{") && /^[A-Za-z0-9+/=\s]+$/.test(purchase_token.trim());
      if (!looksBase64) {
        // 폴백하려면 base64 영수증이 필요함 — 없으면 pending으로 표시
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ status: "pending", last_verified_date: new Date().toISOString() }) }
        );
        return res200({ ok: false, error: "invalid ios token format for fallback" });
      }

      // verifyReceipt: Prod -> 21007 -> Sandbox 재시도
      let resp = await callAppleReceipt(APPLE_PROD, purchase_token!, APPLE_SHARED_SECRET);
      let isSandbox = false;
      if (resp?.status === 21007) {
        resp = await callAppleReceipt(APPLE_SB, purchase_token!, APPLE_SHARED_SECRET);
        isSandbox = true;
      }
      if (resp?.status !== 0) {
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ status: "pending", last_verified_date: new Date().toISOString(), is_sandbox: isSandbox }) }
        );
        return res200({ ok: false, source: "apple", status: resp?.status });
      }

      // latest_receipt_info 처리(기존 로직)
      const infos = Array.isArray(resp?.latest_receipt_info) ? resp.latest_receipt_info : [];
      const mine = product_id ? infos.filter((it: any) => it.product_id === product_id) : infos;
      const selected = (mine.length ? mine : infos).sort((a: any, b: any) => Number(a.expires_date_ms ?? 0) - Number(b.expires_date_ms ?? 0)).slice(-1)[0];

      if (!selected) {
        await supa(
          `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
          { method: "PATCH", body: JSON.stringify({ status: "expired", last_verified_date: new Date().toISOString(), is_sandbox: isSandbox }) }
        );
        return res200({ ok: true, active: false });
      }

      const expiresMs  = Number(selected.expires_date_ms ?? 0);
      const purchaseMs = Number(selected.original_purchase_date_ms ?? selected.purchase_date_ms ?? 0);
      const active     = expiresMs > Date.now();
      const canceled   = !!selected.cancellation_date_ms;

      const payload2 = {
        product_id: selected.product_id,
        status: canceled ? "canceled" : (active ? "active" : "expired"),
        start_date: purchaseMs ? new Date(purchaseMs).toISOString() : null,
        end_date: expiresMs ? new Date(expiresMs).toISOString() : null,
        last_verified_date: new Date().toISOString(),
        is_sandbox: isSandbox,
      };
      const u2 = await supa(
        `subscriptions?purchase_token=eq.${encodeURIComponent(purchase_token!)}`,
        { method: "PATCH", body: JSON.stringify(payload2) }
      );
      if (!u2.ok) {
        const t = await u2.text();
        return new Response(JSON.stringify({ ok: false, source: "supabase", status: u2.status, body: t }), { status: 500, headers: { "Content-Type": "application/json" } });
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
