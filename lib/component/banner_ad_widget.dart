import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/util/ad_helper.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  AdSize? _adSize;
  bool _loaded = false;

  Future<void> _loadAd() async {
    // 화면 폭에 맞는 Anchored Adaptive 사이즈 계산
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || size == null) {
      // iPad 등에서 null 일 수 있음 -> fallback
      _adSize = AdSize.banner;
    } else {
      _adSize = size;
    }

    final ad = BannerAd(
      size: _adSize!,
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob][BANNER] loaded size=${_adSize?.width}x${_adSize?.height}');
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob][BANNER] failed code=${error.code}, message=${error.message}');
          ad.dispose();
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );
    await ad.load();
  }

  @override
  void initState() {
    super.initState();
    // build 후 MediaQuery 사용 가능 시점에 로드
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프로면 숨김
    final planName = context.watch<UserProvider>().myPlan?.planName ?? 'free';
    if (planName == 'pro') return const SizedBox.shrink();

    if (!_loaded || _ad == null || _adSize == null) {
      // 자리만 확보(0으로 줘도 되지만 iOS 레이아웃 흔들림 방지용)
      return const SizedBox(height: 0);
    }

    // 정확한 사이즈로 감싸주기 (iOS에서 중요)
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true, // 홈 인디케이터에 안 가리게
      child: SizedBox(
        height: _adSize!.height.toDouble(),
        width: _adSize!.width.toDouble(),
        child: Center(child: AdWidget(ad: _ad!)),
      ),
    );
  }
}
