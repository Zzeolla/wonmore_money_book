// lib/util/ad_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wonmore_money_book/util/ad_config.dart'; // for kDebugMode
/// TODO : 출시 전에는 반드시 옵션으로 false 지정 필요 flutter build appbundle --dart-define=USE_TEST_ADS=false
class AdHelper {
  static String get bannerAdUnitId {
    if (AdConfig.useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // ✅ 테스트용
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_BANNER_ID_ANDROID']!
        : dotenv.env['ADMOB_BANNER_ID_IOS']!;
  }

  static String get rewardedInterstitialAdUnitId {
    if (AdConfig.useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5354046379' // ✅ 테스트용
          : 'ca-app-pub-3940256099942544/6978759866';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_REWARDED_ID_ANDROID']!
        : dotenv.env['ADMOB_REWARDED_ID_IOS']!;
  }

  static String get interstitialAdUnitId {
    if (AdConfig.useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // ✅ 테스트용
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID']!
        : dotenv.env['ADMOB_INTERSTITIAL_ID_IOS']!;
  }
}