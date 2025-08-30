import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/model/budget_model.dart';
import 'package:wonmore_money_book/model/shared_user_model.dart';
import 'package:wonmore_money_book/model/subscription_model.dart';
import 'package:wonmore_money_book/model/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  String? _userId;
  String? _ownerId;
  String? _budgetId;
  String? _profileImageUrl;
  UserModel? _myInfo;
  bool _imageExists = false;
  bool _justSignedIn = false;
  List<BudgetModel>? _budgets;
  List<BudgetModel>? _myBudgets;
  List<String>? _permissionBudgets;
  List<String>? _sharedOwnerIds;
  List<String>? _sharedUserIds;
  List<UserModel>? _sharedUsers;
  List<UserModel>? _mySharedUsers;
  List<UserModel>? _sharedOwnerUsers;
  SubscriptionModel? _myPlan;

  User? get currentUser => _currentUser;

  String? get userId => _userId;

  String? get ownerId => _ownerId;

  String? get budgetId => _budgetId;

  String? get profileImageUrl => _profileImageUrl;

  UserModel? get myInfo => _myInfo;

  bool get imageExists => _imageExists;

  bool get isLoggedIn => _userId != null;

  bool get justSignedIn => _justSignedIn;

  List<BudgetModel>? get budgets => _budgets;

  List<BudgetModel>? get myBudgets => _myBudgets;

  List<String>? get permissionBudgets => _permissionBudgets;

  List<String>? get sharedOwnerIds => _sharedOwnerIds;

  List<String>? get sharedUserIds => _sharedUserIds;

  List<UserModel>? get sharedUsers => _sharedUsers;

  List<UserModel>? get mySharedUsers => _mySharedUsers;

  List<UserModel>? get sharedOwnerUsers => _sharedOwnerUsers;

  SubscriptionModel? get myPlan => _myPlan;

  Future<void> initializeUserProvider() async {
    _currentUser = Supabase.instance.client.auth.currentUser;
    _userId = _currentUser?.id;

    if (_currentUser != null) {
      final response =
          await Supabase.instance.client.from('users').select('*').eq('id', _userId!).single();

      _myInfo = UserModel.fromJson(response);
      _myPlan = await loadUserSubscription(_userId!) ?? SubscriptionModel.free();

      _ownerId = (response['last_owner_id'] as String?) ?? _userId;
      _budgetId = response['last_budget_id'] as String?;

      _profileImageUrl =
          Supabase.instance.client.storage.from('avatars').getPublicUrl('$_userId/profile.png');

      await loadSharedUsers();
      await _validationOwnerId();
      await loadBudgets();
      await _validationBudgetId();
    } else {
      _ownerId = null;
      _budgetId = null;
      _profileImageUrl = null;
      _myInfo = UserModel();
      _myPlan = SubscriptionModel.free();
      _imageExists = false;
      _budgets = [];
      _myBudgets = [];
      _permissionBudgets = [];
      _sharedOwnerIds = [];
      _sharedUserIds = [];
      _sharedUsers = [];
      _mySharedUsers = [];
      _sharedOwnerUsers = [];
    }
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _currentUser = user;
    _userId = _currentUser?.id;
    // if (_userId != null) {
    //   final response = await Supabase.instance.client
    //       .from('users')
    //       .select('*')
    //       .eq('id', _userId!)
    //       .single();
    //   _myInfo = UserModel.fromJson(response);
    //
    //   _profileImageUrl = Supabase.instance.client.storage
    //       .from('avatars')
    //       .getPublicUrl('$_userId/profile.png');
    // }

    // await checkImageExists();

    notifyListeners();
  }

  Future<void> setOwnerId(String ownerId) async {
    _ownerId = ownerId;
    await loadSharedUsers();
    await _validationOwnerId();
    await loadBudgets();

    final uid = _userId;
    if (uid != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('last_budget_id')
          .eq('id', uid)
          .maybeSingle();

      final lastBudgetId = response?['last_budget_id'] as String?;
      if (lastBudgetId != null && (_permissionBudgets ?? []).contains(lastBudgetId)) {
        _budgetId = lastBudgetId;
      } else {
        final mainBudget = (_budgets ?? []).firstWhere(
          (b) => b.isMain == true,
          orElse: () => (_budgets?.isNotEmpty ?? false) ? _budgets!.first : BudgetModel(),
        );
        _budgetId = mainBudget.id;
      }
      await Supabase.instance.client.from('users').update({
        'last_owner_id': _ownerId,
        'last_budget_id': _budgetId,
      }).eq('id', _userId!);
    }

    notifyListeners();
  }

  Future<void> setBudgetId(String budgetId) async {
    _budgetId = budgetId;

    final uid = _userId;
    if (uid != null) {
      await Supabase.instance.client
          .from('users')
          .update({'last_budget_id': _budgetId}).eq('id', uid);
    }
    notifyListeners();
  }

  set justSignedIn(bool value) {
    _justSignedIn = value;
    notifyListeners();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _userId = null;
    _ownerId = null;
    _budgetId = null;
    _myPlan = SubscriptionModel.free(); // ← 여기!
    notifyListeners();
  }

  Future<void> _validationOwnerId() async {
    if (_sharedOwnerIds == null || _sharedOwnerIds!.isEmpty) {
      _ownerId = _userId;
    } else if (_ownerId == null || !_sharedOwnerIds!.contains(_ownerId)) {
      _ownerId = _userId;
    }
    notifyListeners();
  }

  Future<void> _validationBudgetId() async {
    if (_userId == null) return;

    final response = await Supabase.instance.client
        .from('users')
        .select('last_budget_id')
        .eq('id', _userId!)
        .maybeSingle();

    final lastBudgetId = response?['last_budget_id'] as String?;
    if (lastBudgetId != null && (_permissionBudgets ?? []).contains(lastBudgetId)) {
      _budgetId = lastBudgetId;
    }
    notifyListeners();
  }

  Future<void> loadSharedUsers() async {
    try {
      final uid = _userId;
      final oid = _ownerId;
      if (uid == null) {
        debugPrint('[loadSharedUsers] skip: userId is null');
        _sharedOwnerIds = [];
        _sharedOwnerUsers = [];
        _sharedUserIds = [];
        _sharedUsers = [];
        _mySharedUsers = [];
        notifyListeners();
        return;
      }

      // 1) 내가 속한 ownerIds
      final ownerRows =
          await Supabase.instance.client.from('shared_users').select('owner_id').eq('user_id', uid);

      final sharedOwnerGroup = (ownerRows as List).map((e) => SharedUserModel.fromJson(e)).toList();
      _sharedOwnerIds = sharedOwnerGroup.map((e) => e.ownerId!).toList();

      // 1-1) owner 유저 정보
      if ((_sharedOwnerIds ?? []).isNotEmpty) {
        final ownerUsers = await Supabase.instance.client
            .from('users')
            .select('*')
            .inFilter('id', _sharedOwnerIds!);
        _sharedOwnerUsers = (ownerUsers as List).map((e) => UserModel.fromJson(e)).toList();
      } else {
        _sharedOwnerUsers = [];
      }

      // 2) 현재 선택된 owner 그룹 멤버들
      if (oid != null) {
        final userIdRows = await Supabase.instance.client
            .from('shared_users')
            .select('user_id')
            .eq('owner_id', oid);

        final sharedUserGroup =
            (userIdRows as List).map((e) => SharedUserModel.fromJson(e)).toList();
        _sharedUserIds = sharedUserGroup.map((e) => e.userId!).toList();

        if ((_sharedUserIds ?? []).isNotEmpty) {
          final users = await Supabase.instance.client
              .from('users')
              .select('*')
              .inFilter('id', _sharedUserIds!);
          _sharedUsers = (users as List).map((e) => UserModel.fromJson(e)).toList();
        } else {
          _sharedUsers = [];
        }
      } else {
        debugPrint('[loadSharedUsers] ownerId is null → skip group users');
        _sharedUserIds = [];
        _sharedUsers = [];
      }

      // 3) 내가 owner인 그룹(owner_id == _userId)의 공유 대상
      final mySharedRows =
          await Supabase.instance.client.from('shared_users').select('user_id').eq('owner_id', uid);

      final mySharedGroup = (mySharedRows as List).map((e) => SharedUserModel.fromJson(e)).toList();
      final mySharedIds = mySharedGroup.map((e) => e.userId!).toList();

      if (mySharedIds.isNotEmpty) {
        final myUsers =
            await Supabase.instance.client.from('users').select('*').inFilter('id', mySharedIds);
        _mySharedUsers = (myUsers as List).map((e) => UserModel.fromJson(e)).toList();
      } else {
        _mySharedUsers = [];
      }

      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ loadSharedUsers error: $e\n$st');
      _sharedOwnerIds ??= [];
      _sharedOwnerUsers ??= [];
      _sharedUserIds ??= [];
      _sharedUsers ??= [];
      _mySharedUsers ??= [];
      notifyListeners();
    }
  }

  Future<void> loadBudgets() async {
    try {
      final uid = _userId;
      final oid = _ownerId;
      if (oid == null || uid == null) {
        debugPrint('[loadBudgets] skip: ownerId/userId is null');
        _budgets = [];
        _myBudgets = [];
        _permissionBudgets = [];
        notifyListeners();
        return;
      }

      // owner의 모든 budget id
      final idRows =
          await Supabase.instance.client.from('budgets').select('id').eq('owner_id', oid);
      final allBudgetIds =
          (idRows as List).map((e) => BudgetModel.fromJson(e)).map((e) => e.id!).toList();

      // 내가 권한 가진 budget id
      final permRows = await Supabase.instance.client
          .from('budget_permissions')
          .select('budget_id')
          .eq('user_id', uid);
      final permittedIds = (permRows as List).map((e) => e['budget_id'] as String).toList();

      _permissionBudgets = allBudgetIds.where((id) => permittedIds.contains(id)).toList();

      // 권한 있는 budget 상세
      if ((_permissionBudgets ?? []).isNotEmpty) {
        final budgetsRows = await Supabase.instance.client
            .from('budgets')
            .select('*')
            .inFilter('id', _permissionBudgets!);
        _budgets = (budgetsRows as List).map((e) => BudgetModel.fromJson(e)).toList();
      } else {
        _budgets = [];
      }

      // 내가 owner인 budgets
      final myRows = await Supabase.instance.client.from('budgets').select('*').eq('owner_id', uid);
      _myBudgets = (myRows as List).map((e) => BudgetModel.fromJson(e)).toList();

      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ loadBudgets error: $e\n$st');
      _budgets ??= [];
      _myBudgets ??= [];
      _permissionBudgets ??= [];
      notifyListeners();
    }
  }

  Future<void> checkImageExists() async {
    try {
      final url = _profileImageUrl;
      if (url == null) {
        _imageExists = false;
      } else {
        final response = await http.head(Uri.parse(url));
        _imageExists = response.statusCode == 200;
      }
    } catch (_) {
      _imageExists = false;
    }
    notifyListeners();
  }

  Future<void> addBudget(String title, Set<String> selectedUserIds) async {
    final uid = _userId;
    if (uid == null) return;

    final supabase = Supabase.instance.client;
    final newBudgetId = const Uuid().v4();

    await supabase.from('budgets').insert(
        {'id': newBudgetId, 'owner_id': uid, 'name': title, 'updated_by': uid, 'is_main': false});

    // 2) owner는 제외하고 나머지 사용자만 권한 부여 (중복 안전)
    final others = selectedUserIds.where((u) => u != uid).toSet();
    if (others.isNotEmpty) {
      final rows = others.map((u) => {
        'budget_id': newBudgetId,
        'user_id': u,
      }).toList();

      await supabase
          .from('budget_permissions')
          .upsert(rows, onConflict: 'budget_id,user_id'); // ★ 중복 insert 방지
    }

    await loadBudgets();
    notifyListeners();
  }

  Future<void> updateBudget(String budgetId, String title, Set<String> selectedUserIds) async {
    final uid = _userId;
    if (uid == null) return;

    final supabase = Supabase.instance.client;

    // 1. budgets 테이블에서 제목 업데이트
    await supabase.from('budgets').update({
      'name': title,
      'updated_by': uid,
    }).eq('id', budgetId);

    // 2) 현재 권한 조회
    final currentRows = await supabase
        .from('budget_permissions')
        .select('user_id')
        .eq('budget_id', budgetId);

    final current = currentRows
        .map<String>((r) => r['user_id'] as String)
        .toSet();

    // 2. 기존 권한 삭제
    await supabase.from('budget_permissions').delete().eq('budget_id', budgetId);

    // 3) 최종 목표 권한 집합 = 선택 + owner(항상 포함)
    final desired = {...selectedUserIds, uid};
    final desiredOthers = desired.where((u) => u != uid).toSet(); // owner 제외한 나머지

    // 4) diff 계산 (owner는 항상 유지되므로 current에 있어도 제거하지 않음)
    final currentOthers = current.where((u) => u != uid).toSet();
    final toAdd = desiredOthers.difference(currentOthers);
    final toRemove = currentOthers.difference(desiredOthers);

    if (toAdd.isNotEmpty) {
      final rows = toAdd.map((u) => {
        'budget_id': budgetId,
        'user_id': u,
      }).toList();

      await supabase
          .from('budget_permissions')
          .upsert(rows, onConflict: 'budget_id,user_id'); // ★ 안전
    }

    if (toRemove.isNotEmpty) {
      await supabase
          .from('budget_permissions')
          .delete()
          .eq('budget_id', budgetId)
          .inFilter('user_id', toRemove.toList());
    }
    await loadBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String budgetId) async {
    final supabase = Supabase.instance.client;

    // 1. 이 budget을 참조하는 user 모두 가져오기
    final referencingUsers =
        await supabase.from('users').select('id').eq('last_budget_id', budgetId);

    for (final user in referencingUsers) {
      final userId = user['id'];

      // 2. 해당 사용자가 소유한 main 가계부 찾아오기
      final mainBudget = await supabase
          .from('budgets')
          .select('id')
          .eq('owner_id', userId)
          .eq('is_main', true)
          .maybeSingle();

      final mainBudgetId = mainBudget?['id'];

      // 3. users 테이블 업데이트
      await supabase.from('users').update({
        'last_owner_id': userId,
        'last_budget_id': mainBudgetId,
      }).eq('id', userId);
    }

    // 1. 권한 정보 먼저 삭제
    await supabase.from('budget_permissions').delete().eq('budget_id', budgetId);

    // 2. 예산 자체 삭제
    await supabase.from('budgets').delete().eq('id', budgetId);

    // 3. 현재 선택 중인 예산이면 교체
    if (_budgetId == budgetId) {
      // budgets 테이블에서 is_main == true 인 예산 가져오기
      final mainBudgetResponse = await supabase
          .from('budgets')
          .select('id')
          .eq('owner_id', _ownerId!)
          .eq('is_main', true)
          .maybeSingle();

      final newBudgetId = mainBudgetResponse?['id'];

      _budgetId = newBudgetId;

      await setBudgetId(_budgetId!);
    }

    await loadBudgets();
    notifyListeners();
  }

  Future<SubscriptionModel?> loadUserSubscription(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      final nowIso = DateTime.now().toUtc().toIso8601String();

      // 1) 현재 유효한 구독 1건 찾기: start_date <= now < end_date
      final sub = await supabase
          .from('subscriptions')
          .select('id, user_id, plan_id, start_date, end_date') // 필요한 것만
          .eq('user_id', userId)
          .lte('start_date', nowIso)
          .gt('end_date', nowIso)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      // 레코드 없으면 free
      if (sub == null) return null;

      final String planId = sub['plan_id'];

      // 2. 요금제 정보 가져오기
      final planInfo = await supabase
          .from('subscription_plans')
          .select('name, ads_enabled, max_budgets, max_shared_users')
          .eq('id', planId)
          .single();

      return SubscriptionModel(
        id: sub['id'],
        userId: sub['user_id'],
        planName: planInfo['name'],               // ← 여기서 name을 planName으로
        startDate: DateTime.parse(sub['start_date']),
        endDate: DateTime.parse(sub['end_date']),
        adsEnabled: planInfo['ads_enabled'],
        maxBudgets: planInfo['max_budgets'],
        maxSharedUsers: planInfo['max_shared_users'] ?? 10000,
      );
    } catch (e, st) {
      debugPrint('❌ loadUserSubscription error: $e\n$st');
      return null; // 실패 시 free()로 대체되도록
    }
  }
}
