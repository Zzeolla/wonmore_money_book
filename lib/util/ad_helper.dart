// lib/util/ad_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // for kDebugMode

class AdHelper {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // ✅ 테스트용
          : 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return Platform.isAndroid
          ? dotenv.env['ADMOB_BANNER_ID_ANDROID']!
          : dotenv.env['ADMOB_BANNER_ID_IOS']!;
    }
  }

  static String get rewardedInterstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5354046379' // ✅ 테스트용
          : 'ca-app-pub-3940256099942544/6978759866';
    } else {
      return Platform.isAndroid
          ? dotenv.env['ADMOB_REWARDED_ID_ANDROID']!
          : dotenv.env['ADMOB_REWARDED_ID_IOS']!;
    }
  }
}
