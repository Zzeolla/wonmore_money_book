import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const _kMainTutorialKey = 'tutorial_main_done';

  static Future<bool> isMainTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMainTutorialKey) ?? false;
  }

  static Future<void> setMainTutorialDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMainTutorialKey, value);
  }

  /// 더보기 > 튜토리얼 재시작 용
  static Future<void> resetMainTutorial() async {
    await setMainTutorialDone(false);
  }
}
