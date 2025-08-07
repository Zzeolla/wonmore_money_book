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
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', _userId!)
          .single();
      _myInfo = UserModel.fromJson(response);
      _myPlan = await loadUserSubscription(_userId!);
      _profileImageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('$_userId/profile.png');
      await loadSharedUsers();
      await loadBudgets();
    } else {
      _ownerId = null;
      _budgetId = null;
      _profileImageUrl = null;
      _myInfo = UserModel();
      _myPlan = SubscriptionModel();
      _imageExists = false;
      _budgets = [];
      _myBudgets = [];
      _permissionBudgets = [];
      _sharedOwnerIds = [];
      _sharedUserIds = [];
      _sharedUsers = [];
      _mySharedUsers = [];
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

    final response = await Supabase.instance.client
        .from('users')
        .select('last_budget_id')
        .eq('id', _userId!)
        .maybeSingle();

    final lastBudgetId = response?['last_budget_id'];

    if (lastBudgetId != null && _permissionBudgets!.contains(lastBudgetId)) {
      _budgetId = lastBudgetId;
    } else {
      final mainBudget = _budgets!.firstWhere(
            (b) => b.isMain == true,
        orElse: () => _budgets!.first,
      );
      _budgetId = mainBudget.id;
    }

    await Supabase.instance.client.from('users').update({
      'last_owner_id': _ownerId,
      'last_budget_id': _budgetId,
    }).eq('id', _userId!);

    // if (_userId != null) {
    //   // 1. main budget 가져오기
    //   final response = await client
    //       .from('budgets')
    //       .select('id')
    //       .eq('owner_id', _ownerId!)
    //       .eq('is_main', true)
    //       .maybeSingle();
    //
    //   final mainBudgetId = response?['id'] as String?;
    //
    //   if (mainBudgetId != null) {
    //     _budgetId = mainBudgetId;
    //
    //     // 2. users 테이블에 last_owner_id & last_budget_id 업데이트
    //     await client.from('users').update({
    //       'last_owner_id': _ownerId,
    //       'last_budget_id': _budgetId,
    //     }).eq('id', _userId!);
    //   } else {
    //     // 예외 처리: main budget이 없을 때 (선택)
    //     _budgetId = null;
    //   }
    // }
    notifyListeners();
  }

  Future<void> setBudgetId(String budgetId) async {
    _budgetId = budgetId;

    if (_userId != null) {
      await Supabase.instance.client
          .from('users')
          .update({'last_budget_id': _budgetId})
          .eq('id', _userId!);
    }
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
    notifyListeners();
  }

  Future<void> _validationOwnerId() async {
    if (!_sharedOwnerIds!.contains(_ownerId)) {
      _ownerId = _userId;
    }
    // final response = await Supabase.instance.client
    //     .from('users')
    //     .select('last_owner_id')
    //     .eq('id', _userId!)
    //     .maybeSingle();
    //
    // final lastOwnerId = response?['last_owner_id'];
    //
    // if (lastOwnerId != null && _sharedOwnerIds!.contains(lastOwnerId)) {
    //   _ownerId = lastOwnerId;
    // } else {
    //   _ownerId = _userId;
    // }

    notifyListeners();
  }

    Future<void> _validationBudgetId() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('last_budget_id')
        .eq('id', _userId!)
        .maybeSingle();

    final lastBudgetId = response?['last_budget_id'];

    if (lastBudgetId != null && _permissionBudgets!.contains(lastBudgetId)) {
      _budgetId = lastBudgetId;
    }
    notifyListeners();
  }

  Future<void> loadSharedUsers() async {
    // shared_users 테이블을 통해 내가 속한 ownerId들을 먼저 가져옴
    final responseGetOwner = await Supabase.instance.client
        .from('shared_users')
        .select('owner_id')
        .eq('user_id', _userId!);
    final sharedOwnerGroup = responseGetOwner.map(SharedUserModel.fromJson).toList();
    _sharedOwnerIds = sharedOwnerGroup.map((e) => e.ownerId!).toList();

    final responseSharedOwnerUser = await Supabase.instance.client
        .from('users')
        .select('*')
        .inFilter('id', _sharedOwnerIds!);
    _sharedOwnerUsers = responseSharedOwnerUser.map(UserModel.fromJson).toList();

    // 현재 내가 선택하고 있는 ownerId를 공유받고 있는 userId
    final responseGetUser = await Supabase.instance.client
        .from('shared_users')
        .select('user_id')
        .eq('owner_id', _ownerId!);
    final sharedUserGroup = responseGetUser.map(SharedUserModel.fromJson).toList();
    _sharedUserIds = sharedUserGroup.map((e) => e.userId!).toList();

    // 현재 ownerID 그룹에 포함되어 있는 user들으 의 정보 가져옴
    final userResponse = await Supabase.instance.client
        .from('users')
        .select('*')
        .inFilter('id', _sharedUserIds!);
    _sharedUsers = userResponse.map(UserModel.fromJson).toList();

    final responseGetSharedUser = await Supabase.instance.client
        .from('shared_users')
        .select('user_id')
        .eq('owner_id', _userId!);
    final mySharedUserGroup = responseGetSharedUser.map(SharedUserModel.fromJson).toList();
    final mySharedUserIds = mySharedUserGroup.map((e) => e.userId!).toList();

    final mySharedUserResponse = await Supabase.instance.client
        .from('users')
        .select('*')
        .inFilter('id', mySharedUserIds);
    _mySharedUsers = mySharedUserResponse.map(UserModel.fromJson).toList();
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    final response = await Supabase.instance.client
        .from('budgets')
        .select('id')
        .eq('owner_id', _ownerId!);
    final allBudgetIds = response.map(BudgetModel.fromJson).toList().map((e) => e.id!).toList();

    final permissionResponse = await Supabase.instance.client
        .from('budget_permissions')
        .select('budget_id')
        .eq('user_id', _userId!);
    final permittedBudgetIds = permissionResponse
        .map((e) => e['budget_id'] as String)
        .toList();

    _permissionBudgets = allBudgetIds
        .where((id) => permittedBudgetIds.contains(id))
        .toList();

    final finalBudgetResponse = await Supabase.instance.client
        .from('budgets')
        .select('*')
        .inFilter('id', _permissionBudgets!);
    _budgets = finalBudgetResponse.map(BudgetModel.fromJson).toList();

    final myBudgetResponse = await Supabase.instance.client
        .from('budgets')
        .select('*')
        .eq('owner_id', _userId!);
    _myBudgets = myBudgetResponse.map(BudgetModel.fromJson).toList();
    notifyListeners();
  }

  Future<void> checkImageExists() async {
    try {
      final response = await http.head(Uri.parse(_profileImageUrl!));
      _imageExists = response.statusCode == 200;
    } catch (e) {
      _imageExists =  false;
    }
    notifyListeners();
  }

  Future<void> addBudget(String title, Set<String> selectedUserIds) async {
    final fullUserIds = {...selectedUserIds, _userId!};

    final supabase = Supabase.instance.client;

    final newBudgetId = const Uuid().v4();
    await supabase.from('budgets').insert({
      'id': newBudgetId,
      'owner_id': _userId,
      'name': title,
      'updated_by': _userId,
      'is_main': false
    });

    if (fullUserIds.isNotEmpty) {
      final rows = fullUserIds.map((userId) => {
        'budget_id': newBudgetId,
        'user_id': userId,
      }).toList();

      await supabase.from('budget_permissions').insert(rows);
    }

    await loadBudgets();
    notifyListeners();
  }

  Future<void> updateBudget(String budgetId, String title, Set<String> selectedUserIds) async {
    final fullUserIds = {...selectedUserIds, _userId!};
    final supabase = Supabase.instance.client;

    // 1. budgets 테이블에서 제목 업데이트
    await supabase.from('budgets').update({
      'name': title,
      'updated_by': _userId,
    }).eq('id', budgetId);

    // 2. 기존 권한 삭제
    await supabase.from('budget_permissions').delete().eq('budget_id', budgetId);

    // 3. 새로운 권한 삽입
    if (fullUserIds.isNotEmpty) {
      final rows = fullUserIds.map((userId) => {
        'budget_id': budgetId,
        'user_id': userId,
      }).toList();

      await supabase.from('budget_permissions').insert(rows);
    }

    await loadBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String budgetId) async {
    final supabase = Supabase.instance.client;

    // 1. 이 budget을 참조하는 user 모두 가져오기
    final referencingUsers = await supabase
        .from('users')
        .select('id')
        .eq('last_budget_id', budgetId);

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
      await supabase
          .from('users')
          .update({
        'last_owner_id': userId,
        'last_budget_id': mainBudgetId,
      })
          .eq('id', userId);
    }

    // 1. 권한 정보 먼저 삭제
    await supabase
        .from('budget_permissions')
        .delete()
        .eq('budget_id', budgetId);

    // 2. 예산 자체 삭제
    await supabase
        .from('budgets')
        .delete()
        .eq('id', budgetId);

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

      // 1. 활성 구독 가져오기
      final response = await supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .single();

      final planName = response['plan_name'];

      // 2. 요금제 정보 가져오기
      final planInfo = await supabase
          .from('subscription_plans')
          .select('ads_enabled, max_budgets, max_shared_users')
          .eq('name', planName)
          .single();

      // 3. 통합 모델 생성
      return SubscriptionModel(
        id: response['id'],
        userId: response['user_id'],
        planName: response['plan_name'],
        startDate: DateTime.parse(response['start_date']),
        endDate: response['end_date'] != null
            ? DateTime.parse(response['end_date'])
            : null,
        isActive: response['is_active'],
        adsEnabled: planInfo['ads_enabled'],
        maxBudgets: planInfo['max_budgets'],
        maxSharedUsers: planInfo['max_shared_users'],
      );
    } catch (e) {
      print('구독 정보 로드 실패: $e');
      return null;
    }
  }
}
