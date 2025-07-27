import 'package:shared_preferences/shared_preferences.dart';

class RecordAdService {
  static const _keyDate = 'record_limit_date';
  static const _keyCount = 'record_limit_count';
  static const _keyAdCount = 'record_limit_ad_count';

  static Future<void> resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final lastDate = prefs.getString(_keyDate);

    if (lastDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
      await prefs.setInt(_keyAdCount, 0);
    }
  }

  static Future<int> getTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCount) ?? 0;
  }

  static Future<int> getAdWatchedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAdCount) ?? 0;
  }

  static Future<void> incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getTodayCount();
    await prefs.setInt(_keyCount, count + 1);
  }

  static Future<void> incrementAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getAdWatchedCount();
    await prefs.setInt(_keyAdCount, count + 1);
  }
}
