// lib/screen/paywall_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/service/iap_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loadingProducts = true;
  bool _buying = false;
  String? _price;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initProducts();
  }

  Future<void> _initProducts() async {
    try {
      await IapService().loadProductsIfNeeded();
      final price = IapService().getMonthlyPriceText();
      if (!mounted) return;
      setState(() {
        _price = price;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '상품 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.\n$e';
        _loadingProducts = false;
      });
    }
  }

  Future<void> _buy() async {
    if (_buying) return;
    setState(() => _buying = true);
    try {
      await IapService().buyMonthly();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 진행 중입니다… 잠시만 기다려주세요.')),
      );
      // 낙관 승인 → startListener 콜백에서 UserProvider.loadUserSubscription()가 호출됨
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구매 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _restore() async {
    try {
      await IapService().restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 내역을 확인 중입니다.')),
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
    // DB가 진실: UserProvider 기준으로 표시. (없으면 IapService().isPro를 폴백)
    final myPlan = context.watch<UserProvider>().myPlan;
    final isPro = myPlan?.planName == 'pro';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRO 업그레이드'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingProducts
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(isPro ? Icons.verified : Icons.lock_open, color: isPro ? Colors.green : null),
                const SizedBox(width: 8),
                Text(isPro ? '현재 플랜: PRO 활성' : '현재 플랜: 무료',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _FeatureTile(icon: Icons.block, text: '광고 제거'),
            _FeatureTile(icon: Icons.all_inclusive, text: '공유 유저 무제한'),
            _FeatureTile(icon: Icons.library_books, text: '가계부 확장 (3개 → 7개)'),
            const SizedBox(height: 24),

            // 구매 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPro || _buying ? null : _buy,
                child: Text(
                  isPro
                      ? '이미 PRO 입니다'
                      : (_price == null ? 'PRO 월 구독' : 'PRO 월 구독 ($_price)'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _restore,
                child: const Text('구매 복원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const Spacer(),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              kReleaseMode
                  ? '구독은 Google Play 결제 규정을 따르며, 취소/환불은 Google Play에서 관리됩니다.'
                  : '내부 테스트 모드(비상업용). 실제 과금되지 않을 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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
