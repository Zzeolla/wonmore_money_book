import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wonmore_money_book/util/ad_helper.dart';

class RewardedInterstitialAdService {
  RewardedInterstitialAd? _ad;

  void loadAd() {
    RewardedInterstitialAd.load(
      adUnitId: AdHelper.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          print('광고 로드 실패: $error');
        },
      ),
    );
  }

  bool get isReady => _ad != null;

  void showAd(Function onRewarded) {
    if (_ad == null) return;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadAd();
      },
    );

    _ad!.show(onUserEarnedReward: (ad, reward) {
      onRewarded();
    });

    _ad = null;
  }
}
