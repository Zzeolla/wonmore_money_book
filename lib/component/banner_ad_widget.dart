import 'dart:io';
import 'package:flutter/foundation.dart';
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

  // 화면 표시용 미니 로그 텍스트
  String _status = 'init…';

  // 디버그 라벨을 언제 보일지(원하면 항상 true로)
  bool get _showLabel => kDebugMode; // 필요하면 || AdConfig.useTestAds

  Future<void> _loadAd() async {
    final widthPx = MediaQuery.of(context).size.width.truncate();

    // Adaptive 시도
    AdSize? adaptive = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthPx);

    // 폰=고정 50dp, 태블릿=Adaptive (원하면 모두 Adaptive로 바꿔도 됨)
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    _adSize = isTablet ? (adaptive ?? AdSize.banner) : AdSize.banner;

    setState(() => _status = 'requesting ${_adSize!.width}x${_adSize!.height}');

    final ad = BannerAd(
      size: _adSize!,
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
            _status = 'loaded ${_adSize!.width}x${_adSize!.height}';
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _ad = null;
            _loaded = false;
            _status = 'failed code=${error.code} msg=${error.message}';
          });
        },
        onAdImpression: (ad) {
          setState(() {
            _status = 'impression ✅ ${_adSize!.width}x${_adSize!.height}';
          });
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          if (_showLabel) {
            setState(() {
              _status = 'paid ${valueMicros}µ ${currencyCode}';
            });
          }
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
    // PRO면 숨김
    final planName = context.watch<UserProvider>().myPlan?.planName ?? 'free';
    if (planName == 'pro') return const SizedBox.shrink();

    final adBox = (_loaded && _ad != null && _adSize != null)
        ? SafeArea(
      top: false, left: false, right: false, bottom: true,
      child: SizedBox(
        height: _adSize!.height.toDouble(),
        width: _adSize!.width.toDouble(),
        child: Center(child: AdWidget(ad: _ad!)),
      ),
    )
        : const SizedBox(height: 0);

    // 배너 + 미니 로그 한 줄
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        adBox,
        if (_showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text(
              _status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
