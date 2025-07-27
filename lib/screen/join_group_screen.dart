import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wonmore_money_book/model/shared_user_model.dart';
import 'package:wonmore_money_book/model/subscription_model.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/service/invite_code_service.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String? _myInviteCode;

  @override
  void initState() {
    super.initState();
    _loadOrCreateInviteCode();
  }

  Future<void> _loadOrCreateInviteCode({bool force = false}) async {
    final client = Supabase.instance.client;
    final userProvider = context.read<UserProvider>();
    final ownerId = userProvider.ownerId;
    final myPlan = userProvider.myPlan ?? SubscriptionModel.free();
    final sharedUserCount = userProvider.sharedUserIds?.length ?? 0;
    final maxAllowed = myPlan.maxSharedUsers;

    if (maxAllowed != null && sharedUserCount >= maxAllowed) {
      if (myPlan.planName == 'free') {
        // 🔒 무료 플랜 제한 도달 → 업그레이드 유도
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('업그레이드 필요'),
            content: Text('공유는 최대 ${maxAllowed}명까지만 가능합니다.\nPro로 업그레이드 해보세요!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/more/plan');

                  /// TODO: 이것도 동일하게 업그레이드 화면 만들어줘
                },
                child: const Text('업그레이드'),
              ),
            ],
          ),
        );
      } else {
        // 🔐 유료 플랜인데도 제한 도달 (이론상 거의 없음)
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('공유 제한 도달'),
            content: const Text('더 이상 사용자를 초대할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final now = DateTime.now().toUtc();
    final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

    Map<String, dynamic>? existing;

    if (!force) {
      existing = await client
          .from('invite_codes')
          .select()
          .eq('owner_id', ownerId!)
          .gte('created_at', tenMinutesAgo.toIso8601String())
          .maybeSingle();
    }
    // 1. 10분 이내 생성된 코드만 조회

    String code;

    if (existing != null && existing['invite_code'] != null) {
      // 유효한 기존 코드가 있음
      code = existing['invite_code'];
    } else {
      // 2. 기존 코드 삭제 (10분 지났거나 중복 생성 방지)
      await client.from('invite_codes').delete().eq('owner_id', ownerId!);

      // 3. 새 코드 생성
      code = InviteCodeService.generateInviteCode();

      await client.from('invite_codes').insert({
        'owner_id': ownerId,
        'invite_code': code,
        'created_at': now.toIso8601String(), // 명시적 삽입 (필요 시)
      });
    }

    setState(() {
      _myInviteCode = code;
    });
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim().toUpperCase();
    final client = Supabase.instance.client;
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final group =
          await client.from('invite_codes').select().eq('invite_code', code).maybeSingle();

      if (group == null) {
        setState(() => _error = '유효하지 않은 초대 코드입니다.');
        return;
      }

      final ownerId = group['owner_id'];

      if (userId == null) {
        setState(() => _error = '로그인이 필요합니다.');
        return;
      }

      // ✅ 1. 이미 참여한 상태인지 확인
      final existing = await client
          .from('shared_users')
          .select()
          .eq('user_id', userId)
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (existing != null) {
        setState(() => _error = '이미 참여한 그룹입니다.');
        return;
      }

      // ✅ 2. 해당 owner의 현재 플랜과 공유 유저 수 확인
      final ownerPlan = await userProvider.loadUserSubscription(ownerId);
      final maxAllowed = ownerPlan?.maxSharedUsers;

      final responseGetUser = await Supabase.instance.client
          .from('shared_users')
          .select('user_id')
          .eq('owner_id', ownerId);
      final sharedUserGroup = responseGetUser.map(SharedUserModel.fromJson).toList();
      final sharedUserCount = sharedUserGroup.map((e) => e.userId!).toList().length;

      if (maxAllowed != null && sharedUserCount >= maxAllowed) {
        // ✅ 초과됨
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('참여 불가'),
            content: Text('이 그룹은 최대 $maxAllowed명까지만 참여할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ 3. 참여 처리
      await client.from('shared_users').insert({
        'user_id': userId,
        'owner_id': ownerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹에 참여했어요!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '오류: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareCode() {
    if (_myInviteCode == null) return;
    final link = 'https://yourapp.com/invite?code=$_myInviteCode';
    Share.share('가계부 그룹 초대코드: $_myInviteCode\n\n👇 참여 링크\n$link');
  }

  void _copyCode() {
    if (_myInviteCode == null) return;
    Clipboard.setData(ClipboardData(text: _myInviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final moneyProvider = context.watch<MoneyProvider>();
    final myPlan = userProvider.myPlan ?? SubscriptionModel.free();
    return Scaffold(
      appBar: CommonAppBar(isMainScreen: false, label: '그룹 공유 및 참여'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔼 내가 그룹장일 때
            const Text(
              '내 그룹 초대하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (userProvider.ownerId != userProvider.userId)
              Column(
                children: [
                  const Text('현재 선택된 그룹은 내 그룹이 아닙니다.'),
                  const SizedBox(height: 12),
                  _customButton(
                    label: '내 그룹으로 이동',
                    onPressed: () async {
                      await userProvider.setOwnerId(userProvider.userId!);
                      final newBudgetId = userProvider.budgetId;
                      await moneyProvider.setOwnerId(userProvider.userId!, newBudgetId!);
                      await _loadOrCreateInviteCode();
                    },
                  ),
                ],
              )
            else if (_myInviteCode != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        _myInviteCode!,
                        style: const TextStyle(
                            fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _customButton(
                          label: '코드 새로 생성',
                          onPressed: () => _loadOrCreateInviteCode(force: true),
                        ),
                      ),
                      Expanded(
                        child: _customButton(
                          label: '공유하기',
                          onPressed: _shareCode,
                        ),
                      ),
                    ],
                  )
                ],
              )
            else
              const CircularProgressIndicator(),

            const SizedBox(height: 40),
            const Divider(height: 40),

            // 🔽 초대 코드 입력
            const Text('초대 코드로 참여하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: '초대 코드 입력',
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _customButton(
              label: '그룹 참여하기',
              onPressed: _isLoading ? () {} : _joinGroup,
            )
          ],
        ),
      ),
    );
  }

  Widget _customButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}
