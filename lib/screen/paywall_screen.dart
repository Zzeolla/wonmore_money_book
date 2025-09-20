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
  bool _loading = true;
  String? _error;
  String? _priceBase;
  String? _priceBasic;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await IapService().loadProducts();
      setState(() {
        // 콘솔에서 실제 productId를 각각 넣어주세요
        _priceBase = IapService().getPriceTextByBasePlan('monthly-base'); // 3일 무료 plan
        _priceBasic = IapService().getPriceTextByBasePlan('monthly-basic'); // 무체험 plan
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

    return Scaffold(
      appBar: AppBar(title: const Text('PRO 업그레이드')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(isPro ? Icons.verified : Icons.lock_open, color: isPro ? Colors.green : null),
                const SizedBox(width: 8),
                Text(isPro ? '현재 플랜: PRO 활성' : '현재 플랜: 무료', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _FeatureTile(icon: Icons.block, text: '광고 제거'),
            _FeatureTile(icon: Icons.all_inclusive, text: '공유 유저 무제한'),
            _FeatureTile(icon: Icons.library_books, text: '가계부 확장 (3개 → 7개)'),
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Colors.grey), // 막대기
            const SizedBox(height: 12),
            ListTile(
              title: const Text('월 구독 (3일 무료)'),
              subtitle: Text(_priceBase ?? '가격 불러오기 실패'),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await IapService().buyByBasePlan('monthly-base');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매 진행 중…')),
                    );
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
            ListTile(
              title: const Text('월 구독 (무료체험 없음)'),
              subtitle: Text(_priceBasic ?? '가격 불러오기 실패'),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await IapService().buyByBasePlan('monthly-basic');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매 진행 중…')),
                    );
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
