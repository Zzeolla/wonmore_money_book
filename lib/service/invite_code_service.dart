import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class InviteCodeService {
  /// 1. 초대코드 생성 (예: YH3G9K)
  static String generateInviteCode([int length = 6]) {
    const chars = '123456789'; // 헷갈리는 글자 제거
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// 2. 그룹에 초대코드 저장
  static Future<String> saveInviteCodeToGroup(String groupId) async {
    final client = Supabase.instance.client;
    final code = generateInviteCode();

    // 중복코드 체크는 생략. 필요시 추가 가능.
    await client
        .from('groups')
        .update({'invite_code': code})
        .eq('id', groupId); // groupId는 네 DB 구조에 맞게 (ex. owner_id)

    return code;
  }

  /// 3. 초대코드 공유 (링크 + 코드)
  static void shareInviteCode(String code) {
    final link = 'https://yourapp.com/invite?code=$code'; // 딥링크 안 쓰면 그냥 텍스트 링크도 OK

    Share.share('우리 가계부 그룹에 초대합니다!\n\n초대코드: $code\n👇 여길 눌러 바로 참여하기\n$link');
  }
}
