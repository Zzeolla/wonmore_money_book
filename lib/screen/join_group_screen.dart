import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
  TutorialCoachMark? _tutorial;
  List<TargetFocus> _targets = [];

  final _keyInviteCode = GlobalKey();
  final _keyJoinGroup = GlobalKey();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String? _myInviteCode;

  @override
  void initState() {
    super.initState();
    _loadOrCreateInviteCode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildTargets(); // 레이아웃 잡힌 뒤 포커스 영역 계산
    });
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
                  Navigator.pushNamed(context, '/more/paywall');
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
    _buildTargets();
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

      // ✅ 4. 주 가계부 자동 공유 처리
      // 4-1) 주 가계부 찾기 (is_main이 없다면 .order('created_at').limit(1) 로 대체)
      final mainBudget = await client
          .from('budgets')
          .select('id')
          .eq('owner_id', ownerId)
          .eq('is_main', true) // 없으면 .order('created_at').limit(1) 로 변경
          .maybeSingle();

      String? mainBudgetId = mainBudget?['id'];
      if (mainBudgetId == null) {
        // fallback: 가장 먼저 만든 가계부를 주 가계부로 간주
        final first = await client
            .from('budgets')
            .select('id')
            .eq('owner_id', ownerId)
            .order('created_at')
            .limit(1)
            .maybeSingle();
        mainBudgetId = first?['id'];
      }

      // 4-2) 권한 등록 (보기만 허용 or 보기+수정, 원하는 정책으로)
      if (mainBudgetId != null) {
        await client.from('budget_permissions').insert({
          'budget_id': mainBudgetId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 컨텍스트 전환 + 데이터 리로드
      await userProvider.setOwnerId(ownerId); // 👈 새 그룹으로 전환

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
      appBar: CommonAppBar(
        isMainScreen: false,
        label: '그룹 공유 및 참여',
        actions: [
          if (userProvider.ownerId == userProvider.userId)
            IconButton(
              icon: Icon(Icons.help_outline, color: Color(0xFFF2F4F6), size: 30),
              onPressed: _showTutorial,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔼 내가 그룹장일 때
            Text(
              key: _keyInviteCode,
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
                          onPressed: () async {
                            await _loadOrCreateInviteCode(force: true);
                            _buildTargets();
                          }
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
            Text('초대 코드로 참여하기',
                key: _keyJoinGroup,style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _buildTargets() {
    final targets = <TargetFocus>[];

    // 1) 초대코드 섹션 (오너일 때만 표기되는 컬럼에 key 달림)
    if (_keyInviteCode.currentContext != null) {
      targets.add(
        TargetFocus(
          keyTarget: _keyInviteCode,
          identify: "invite",
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _tip(
                title: "초대 코드 공유하기",
                body: "가족/지인에게 초대하기 위해 6자리 초대 코드를 공유해주세요.",
              ),
            ),
          ],
        ),
      );
    }

    // 2) 참여 섹션 (헤더 텍스트에 key 달았으니 그걸로 잡기)
    if (_keyJoinGroup.currentContext != null) {
      targets.add(
        TargetFocus(
          keyTarget: _keyJoinGroup,
          identify: "join",
          shape: ShapeLightFocus.RRect,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _tip(
                title: "그룹 참여하기",
                body: "전달받은 6자리 초대 코드를 입력 후 버튼을 누르면 그룹에 참여합니다.",
              ),
            ),
          ],
        ),
      );
    }

    // ✅ 실제로 저장!
    setState(() {
      _targets = targets;
    });
  }

  void _showTutorial() {
    if (_targets.isEmpty) _buildTargets(); // 혹시 비어있으면 한 번 더
    _tutorial = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withOpacity(0.6),
      focusAnimationDuration: Duration.zero,   // ✅ 포커스 인
      unFocusAnimationDuration: Duration.zero, // ✅ 포커스 아웃
      textSkip: "건너뛰기",
      hideSkip: false,
      pulseEnable: true,
      onClickOverlay: (target) {
        _tutorial?.next();
      },
      onClickTarget: (target) {
        _tutorial?.next();
      },
    )..show(context: context);
  }


  Widget _tip({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

}
