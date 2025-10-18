import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/service/iap_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = true;
  String? _error;

  static const String kProductId = 'pro_monthly'; // ✅ Product ID 하나만!

  String? _price;

  @override
  void initState() {
    super.initState();
    IapService().onVerified = () async {
      if (!mounted) return;
      await context.read<UserProvider>().loadUserSubscription();
      if (!mounted) return;
      setState(() {}); // 화면 반영용 (옵션)
    };
    _init();
  }

  @override
  void dispose() {
    IapService().onVerified = null;
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await IapService().loadProducts();
      setState(() {
        _price = IapService().displayPriceOrTrial(
          kProductId,
          regularPriceText: '3일 무료 체험 후 \u20A91,100/월'
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _restore() async {
    try {
      await IapService().restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 내역 확인 중…')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복원 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPlan = context.watch<UserProvider>().myPlan;
    final isPro = myPlan?.planName == 'pro';

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('에러: $_error')));
    }

    final canBuy = _price != null;

    return Scaffold(
      appBar: AppBar(title: const Text('PRO 업그레이드')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(isPro ? Icons.verified : Icons.lock_open,
                    color: isPro ? Colors.green : null),
                const SizedBox(width: 8),
                Text(
                  isPro ? '현재 플랜: PRO 활성' : '현재 플랜: 무료',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FeatureTile(icon: Icons.block, text: '광고 제거'),
            const _FeatureTile(icon: Icons.all_inclusive, text: '공유 유저 무제한'),
            const _FeatureTile(icon: Icons.library_books, text: '가계부 확장 (3개 → 7개)'),
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 12),

            // 단일 상품 섹션
            ListTile(
              title: const Text('월 구독'),
              subtitle: Text(_price ?? '가격 불러오기 실패'),
              trailing: ElevatedButton(
                onPressed: !canBuy ? null : () async {
                  try {
                    await IapService().buy(kProductId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매 진행 중…')),
                    );
                    // B) 폴백: 딜레이 + 재시도
                    unawaited(_waitAndRefreshPlan(retries: 3));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구매 실패: $e')),
                    );
                  }
                },
                child: const Text('구매'),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: _restore,
              child: const Text('구매 복원'),
            ),
            if (kDebugMode)
              ElevatedButton(
                onPressed: () async {
                  await IapService().testInsertDummy();
                },
                child: const Text("DB 더미 Insert 테스트"),
              ),
            // const SizedBox(height: 12),
            //
            // // 2-1) 복원 -> 즉시 검증 (권장 테스트 경로)
            // ElevatedButton(
            //   onPressed: () async {
            //     try {
            //       await IapService().restore();              // 영수증 재발급/복원
            //       await IapService().verifyNow();            // 서버 검증 호출
            //       final sub = await context.read<UserProvider>().loadUserSubscription();
            //       if (!mounted) return;
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text(sub?.planName == 'pro' ? 'PRO 활성화 완료' : '복원 후 검증 완료(아직 미활성)')),
            //       );
            //       setState(() {});
            //     } catch (e) {
            //       if (!mounted) return;
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('복원→검증 실패: $e')));
            //     }
            //   },
            //   child: const Text('복원 → 즉시 검증'),
            // ),
            //
            // const SizedBox(height: 8),
            //
            // // 2-2) 최신 pending 강제 검증
            // TextButton(
            //   onPressed: () async {
            //     final ok = await IapService().verifyLatestPendingOfMine();
            //     final sub = await context.read<UserProvider>().loadUserSubscription();
            //     if (!mounted) return;
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(content: Text(ok
            //           ? (sub?.planName == 'pro' ? '검증 완료: PRO 활성화' : '검증 요청 전송(대기중)')
            //           : '검증 대상 없음')),
            //     );
            //     setState(() {});
            //   },
            //   child: const Text('즉시 검증'),
            // ),
            // const SizedBox(height: 12),
            // FutureBuilder<String>(
            //   future: _latestInfo(),
            //   builder: (_, snap) {
            //     final txt = snap.data ?? '불러오는 중...';
            //     return Text(txt, style: const TextStyle(fontSize: 12));
            //   },
            // ),

          ],
        ),
      ),
    );
  }

  Future<void> _waitAndRefreshPlan({int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      // 첫 시도는 3초 기다렸다가, 이후 2초 간격
      await Future.delayed(Duration(seconds: i == 0 ? 3 : 2));
      await IapService().verifyNow();
      final sub = await context.read<UserProvider>().loadUserSubscription(); // 기본 내 유저
      if (!mounted) return;

      if (sub?.planName == 'pro') {
        // 필요하면 setState(...) or 스낵바
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PRO 활성화 완료')),
        );
        return;
      }
    }
    // 마지막까지 실패 시 안내(선택)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 확인이 지연되고 있어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  Future<String> _latestInfo() async {
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) return '로그인 필요';
      final List<dynamic> rows = await supa
          .from('subscriptions')
          .select('store,status,product_id,created_at,last_verified_date')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return '레코드 없음';

      final r = rows.first as Map<String, dynamic>;
      return 'store=${r['store']}, status=${r['status']}\n'
          'product=${r['product_id']}\n'
          'created=${r['created_at']}\n'
          'verified=${r['last_verified_date'] ?? '-'}';
    } catch (e) {
      return '에러: $e';
    }
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
