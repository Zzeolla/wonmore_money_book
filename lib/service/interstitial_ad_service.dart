import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wonmore_money_book/util/ad_helper.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance = InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

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
        },
      ),
    );
  }

  bool get isReady => _ad != null;

  /// [onRewardEarned] → 보상 획득 시 실행
  /// [onAdClosed] → 광고 닫힌 후 실행
  void showAd({
    required Function onRewardEarned,
    required Function onAdClosed,
  }) {
    final ad = _ad;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadAd();
        onAdClosed();
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      // reward.amount / reward.type 사용 가능 (콘솔의 "1Reward"가 여기에 매핑)
      onRewardEarned();
    });

    _ad = null;
  }
}
