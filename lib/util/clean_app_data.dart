import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> clearAllAppData(BuildContext context) async {
  try {
    // Drift DB 삭제
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File('${dir.path}/db.sqlite'); // 실제 DB 파일명 확인 필요
    if (await dbFile.exists()) {
      await dbFile.delete();
      debugPrint("✅ DB 파일 삭제됨");
    } else {
      debugPrint("❗ DB 파일 없음");
    }

    // SharedPreferences 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("✅ SharedPreferences 초기화됨");

    // 사용자에게 안내
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초기화 완료'),
        content: const Text('앱 데이터를 모두 삭제했습니다.\n앱을 다시 실행해 주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 강제 종료 시도
              Future.delayed(const Duration(milliseconds: 300), () {
                exit(0); // 앱 강제 종료 (주의: 앱스토어 가이드라인 위배 가능)
              });
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  } catch (e) {
    debugPrint("❌ 오류 발생: $e");
  }
}
