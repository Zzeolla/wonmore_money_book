// supabase/functions/anonymize-account/index.ts

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function J(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "authorization, content-type",
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return J({ ok: true });
  if (req.method !== "POST") return J({ error: "Method Not Allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
  const SRV = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (!SUPABASE_URL || !ANON || !SRV) return J({ error: "missing server env" }, 500);

  try {
    // 1) 호출자 본인 확인 (세션 토큰 필수)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return J({ error: "missing Authorization" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: me, error: meErr } = await userClient.auth.getUser();
    if (meErr || !me?.user) return J({ error: "unauthorized" }, 401);
    const userId = me.user.id;

    // 2) 관리자 클라이언트
    const admin = createClient(SUPABASE_URL, SRV);

    // 3) 스토리지 아바타 제거 (있으면)
    try {
      await admin.storage.from("avatars").remove([`${userId}/profile.jpg`]);
    } catch (_) {}

    // 4) 앱 DB의 개인정보 비식별화 (users 행만)
    //    - 이메일: 내부(local) 도메인 가짜값
    //    - 이름/그룹/프로필: 제거
    //    - is_profile: false
    const pseudoEmail = `deleted_${userId}@zlabo.local`;
    const { error: userUpdErr } = await admin
      .from("users")
      .update({
        email: pseudoEmail,
        name: "탈퇴한 사용자",
        group_name: null,
        profile_url: null,
        is_profile: false,
      })
      .eq("id", userId);

    if (userUpdErr) return J({ error: "users anonymize failed", detail: userUpdErr.message }, 500);

    // (선택) 이 유저가 푸시를 못 받도록 토큰 테이블에서 제거
    try {
      await admin.from("user_device_tokens").delete().eq("user_id", userId);
    } catch (_) {}

    // (선택) 공유자리스트/멤버십에서 빠지게 하고 싶으면:
    // await admin.from("shared_users").delete().eq("user_id", userId);

    // 5) 인증 계정 자체 삭제 → 재로그인 불가
    const { error: delAuthErr } = await admin.auth.admin.deleteUser(userId);
    if (delAuthErr) return J({ error: "auth delete failed", detail: delAuthErr.message }, 500);

    return J({ ok: true });
  } catch (e) {
    return J({ ok: false, error: String(e) }, 500);
  }
});
