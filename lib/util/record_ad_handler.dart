import 'package:flutter/material.dart';
import 'package:wonmore_money_book/service/record_ad_service.dart';
import 'package:wonmore_money_book/service/interstitial_ad_service.dart';

class RecordAdHandler {
  static Future<void> tryAddTransaction(BuildContext context, VoidCallback openDialog) async {
    await RecordAdService.resetIfNewDay();
    final todayCount = await RecordAdService.getTodayCount();
    final adWatched = await RecordAdService.getAdWatchedCount();

    final adService = InterstitialAdService();

    final requiredAds = (todayCount + 3) ~/ 4;

    if (todayCount < 2) {
      await RecordAdService.incrementCount();
      openDialog();
      return;
    }

    final needAdNow = (adWatched == 0);

    if (needAdNow) {
      if (adService.isReady) {
        bool rewarded = false;

        adService.showAd(
          onRewardEarned: () async {
            rewarded = true;
            await RecordAdService.incrementAdCount();
            await RecordAdService.incrementCount();
            openDialog();
          },
          onAdClosed: () async {
            if (!rewarded && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('하루 한 번 광고 시청을 부탁드립니다.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        );
        return;
      } else {
        await RecordAdService.incrementCount();
        openDialog();
        return;
      }
    }

    await RecordAdService.incrementCount();
    openDialog();
  }
}

    // if (todayCount == 0) {
    //   await RecordAdService.incrementCount();
    //   openDialog();
    //   return;
    // }
    //
    // if (adWatched == 0 && todayCount < 5) {
    //   if (adService.isReady) {
    //     adService.showAd(() async {
    //       await RecordAdService.incrementAdCount();
    //       await RecordAdService.incrementCount();
    //       openDialog();
    //     });
    //   } else {
    //     openDialog();
    //   }
    //   return;
    // }
    //
    // if (adWatched == 1 && todayCount >= 5) {
    //   if (adService.isReady) {
    //     adService.showAd(() async {
    //       await RecordAdService.incrementAdCount();
    //       await RecordAdService.incrementCount();
    //       openDialog();
    //     });
    //   } else {
    //     openDialog();
    //   }
    //   return;
    // }

//     // 아직 필요한 광고를 다 보지 않았다면
//     if (adWatched < requiredAds) {
//       if (adService.isReady) {
//         adService.showAd(
//           onRewardEarned: () async {
//             // ✅ 보상 받았을 때만 카운트 증가 + 다이얼로그 오픈
//             await RecordAdService.incrementAdCount();
//             await RecordAdService.incrementCount();
//             openDialog();
//           },
//           onAdClosed: () async {
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('앱 운영에 도움이 되도록 잠시 광고 시청을 부탁드립니다.'),
//                   duration: Duration(seconds: 2),
//                 ),
//               );
//             }
//           },
//         );
//         return;
//       } else {
//         await RecordAdService.incrementCount();
//         openDialog();
//         return;
//       }
//     }
//
//     await RecordAdService.incrementCount();
//     openDialog();
//   }
// }
