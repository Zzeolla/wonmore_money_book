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
  late final BannerAd banner;

  @override
  void initState() {
    super.initState();

    final adUnitId = AdHelper.bannerAdUnitId;


    banner = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,

      listener: BannerAdListener(onAdFailedToLoad: (ad, error) {
        ad.dispose();
      }),
      request: AdRequest(),
    );

    banner.load();
  }

  @override
  void dispose() {
    banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final planName = userProvider.myPlan?.planName ?? 'free';
    if (planName == 'pro') return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: AdWidget(ad: banner),
    );
  }
}
