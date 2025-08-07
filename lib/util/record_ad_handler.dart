import 'package:flutter/material.dart';
import 'package:wonmore_money_book/service/record_ad_service.dart';
import 'package:wonmore_money_book/service/interstitial_ad_service.dart';

class RecordAdHandler {
  static Future<void> tryAddTransaction(BuildContext context, VoidCallback openDialog) async {
    await RecordAdService.resetIfNewDay();
    final todayCount = await RecordAdService.getTodayCount();
    final adWatched = await RecordAdService.getAdWatchedCount();

    final adService = InterstitialAdService();

    if (todayCount == 0) {
      await RecordAdService.incrementCount();
      openDialog();
      return;
    }

    if (adWatched == 0 && todayCount < 5) {
      if (adService.isReady) {
        adService.showAd(() async {
          await RecordAdService.incrementAdCount();
          await RecordAdService.incrementCount();
          openDialog();
        });
      } else {
        openDialog();
      }
      return;
    }

    if (adWatched == 1 && todayCount >= 5) {
      if (adService.isReady) {
        adService.showAd(() async {
          await RecordAdService.incrementAdCount();
          await RecordAdService.incrementCount();
          openDialog();
        });
      } else {
        openDialog();
      }
      return;
    }

    await RecordAdService.incrementCount();
    openDialog();
  }
}
