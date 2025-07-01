import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/model/budget_model.dart';
import 'package:wonmore_money_book/model/shared_user_model.dart';
import 'package:wonmore_money_book/model/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  String? _userId;
  String? _ownerId;
  String? _budgetId;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  bool _imageExists = false;
  bool _justSignedIn = false;
  List<BudgetModel>? _budgets;
  List<String>? _permissionBudgets;
  List<String>? _sharedOwnerIds;
  List<String>? _sharedUserIds;
  List<UserModel>? _sharedUsers;

  User? get currentUser => _currentUser;
  String? get userId => _userId;
  String? get ownerId => _ownerId;
  String? get budgetId => _budgetId;
  String? get userName => _userName ?? '';
  String? get userEmail => _userEmail ?? '';
  String? get profileImageUrl => _profileImageUrl;
  bool get imageExists => _imageExists;
  bool get isLoggedIn => _userId != null;
  bool get justSignedIn => _justSignedIn;
  List<BudgetModel>? get budgets => _budgets;
  List<String>? get permissionBudgets => _permissionBudgets;
  List<String>? get sharedOwnerIds => _sharedOwnerIds;
  List<String>? get sharedUserIds => _sharedUserIds;
  List<UserModel>? get sharedUser => _sharedUsers;

  Future<void> initializeUserProvider() async {
    _currentUser = Supabase.instance.client.auth.currentUser;
    _userId = _currentUser?.id;

    if (_currentUser != null) {
      await loadSharedUsers();
      await loadBudgets();
    } else {
      _ownerId = null;
      _budgetId = null;
      _userName = null;
      _userEmail = null;
      _profileImageUrl = null;
      _imageExists = false;
      _budgets = [];
      _permissionBudgets = [];
      _sharedOwnerIds = [];
      _sharedUserIds = [];
      _sharedUsers = [];
    }
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _currentUser = user;
    _userId = _currentUser?.id;
    if (_userId != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', _userId!)
          .single();
      final myInfo = UserModel.fromJson(response);

      _userName = myInfo.name;
      _userEmail = myInfo.email;

      _profileImageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('$_userId/profile.png');
    }

    await checkImageExists();

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

    final responseGetUser = await Supabase.instance.client
        .from('shared_users')
        .select('user_id')
        .eq('owner_id', _ownerId!);
    final sharedUserGroup = responseGetUser.map(SharedUserModel.fromJson).toList();
    _sharedUserIds = sharedUserGroup.map((e) => e.userId!).toList();

    final userResponse = await Supabase.instance.client
        .from('users')
        .select('*')
        .inFilter('id', _sharedUserIds!);
    _sharedUsers = userResponse.map(UserModel.fromJson).toList();
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
}
