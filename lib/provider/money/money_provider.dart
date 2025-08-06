import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/asset_model.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/category_summary.dart';
import 'package:wonmore_money_book/model/favorite_record_model.dart';
import 'package:wonmore_money_book/model/installment_model.dart';
import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/asset_service.dart';
import 'package:wonmore_money_book/provider/money/category_service.dart';
import 'package:wonmore_money_book/provider/money/favorite_record_service.dart';
import 'package:wonmore_money_book/provider/money/installment_service.dart';
import 'package:wonmore_money_book/provider/money/transaction_service.dart';
import 'package:wonmore_money_book/service/repeat_transaction_service.dart';

class MoneyProvider extends ChangeNotifier {
  final AppDatabase _database;
  final Map<String, List<TransactionModel>> _monthlyCache = {};
  late RepeatTransactionService repeatTransactionService;
  late TransactionService _transactionService;
  late CategoryService _categoryService;
  late AssetService _assetService;
  late FavoriteRecordService _favoriteRecordService;
  late InstallmentService _installmentService;
  String? _currentUserId;
  String? _ownerId;
  String? _budgetId;
  String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _monthlyIncome = 0;
  int _monthlyExpense = 0;
  int _monthlyBalance = 0;

  AppDatabase get database => _database;
  
  // 카테고리 상태 관리 추가
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;
  
  // 자산 상태 관리 추가
  List<AssetModel> _assets = [];
  List<AssetModel> get assets => _assets;

  // 즐겨찾기 거래내역 상태 관리 추가
  List<FavoriteRecordModel> _favoriteRecords = [];
  List<FavoriteRecordModel> get favoriteRecords => _favoriteRecords;

  // // 즐겨찾기 거래내역 상태 관리 추가
  // List<Installment> _installments = [];
  // List<Installment> get installments => _installments;
  
  // 수입/지출 카테고리 getter
  List<CategoryModel> getIncomeCategories() => _categories.where((c) => c.type == TransactionType.income).toList();
  List<CategoryModel> getExpenseCategories() => _categories.where((c) => c.type == TransactionType.expense).toList();
  List<CategoryModel> getTransferCategories() => _categories.where((c) => c.type == TransactionType.transfer).toList();

  // 월별 거래내역 상태 관리
  List<TransactionModel> _monthlyTransactions = [];
  List<TransactionModel> get monthlyTransactions => _monthlyTransactions;

  // 날짜별 수입/지출 합계 상태 관리 추가
  Map<DateTime, Map<String, int>> _dailySummaryMap = {};
  Map<DateTime, Map<String, int>> get dailySummaryMap => _dailySummaryMap;

  MoneyProvider(this._database) {
    // _transactionService = TransactionService(_database, _currentUserId, _ownerId);
    // _categoryService = CategoryService(_database, _currentUserId, _ownerId);
    // _assetService = AssetService(_database, _currentUserId, _ownerId);
    // _favoriteRecordService = FavoriteRecordService(_database, _currentUserId, _ownerId);
    // _installmentService = InstallmentService(_database, _currentUserId, _ownerId);
    // repeatTransactionService = RepeatTransactionService(this);
    //
    // _loadMonthlySummary();
    // _loadAllCategories(); // 앱 시작 시 전체 카테고리 로드
    // _loadAllAssets(); // 앱 시작 시 전체 자산 로드
    // loadFavoriteRecords();
  }

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  int get monthlyIncome => _monthlyIncome;
  int get monthlyExpense => _monthlyExpense;
  int get monthlyBalance => _monthlyBalance;

  // 사용자 ID 설정
  Future<void> setInitialUserId(String? userId, String? ownerId, String? budgetId) async {
    _currentUserId = userId;
    _ownerId = ownerId;
    _budgetId = budgetId;
    _assetService = AssetService(_database, _currentUserId, _ownerId);
    _categoryService = CategoryService(_database, _currentUserId, _ownerId);
    _transactionService = TransactionService(_database, _currentUserId, _ownerId, _budgetId);
    _favoriteRecordService = FavoriteRecordService(_database, _currentUserId, _ownerId, _budgetId);
    _installmentService = InstallmentService(_database, _currentUserId, _ownerId, _budgetId);

    // _categoryService.listenToCategoryChanges(() async {
    //   await _categoryService.reloadCategoriesFromSupabase();
    //   _loadAllCategories();
    // });

    repeatTransactionService = RepeatTransactionService(this);

    await _loadMonthlySummary();
    await _loadAllCategories(); // 앱 시작 시 전체 카테고리 로드
    await _loadAllAssets(); // 앱 시작 시 전체 자산 로드
    await loadFavoriteRecords();
    notifyListeners();
  }

  Future<void> setOwnerId(String newOwnerId, String newBudgetId) async {
    _ownerId = newOwnerId;
    _budgetId = newBudgetId;
    _assetService = AssetService(_database, _currentUserId, _ownerId);
    _categoryService = CategoryService(_database, _currentUserId, _ownerId);
    _transactionService = TransactionService(_database, _currentUserId, _ownerId, _budgetId);
    _favoriteRecordService = FavoriteRecordService(_database, _currentUserId, _ownerId, _budgetId);
    _installmentService = InstallmentService(_database, _currentUserId, _ownerId, _budgetId);

    // 데이터 다시 로드
    await _loadAllAssets();
    await _loadAllCategories();
    await _loadMonthlySummary();
    await loadFavoriteRecords();
    notifyListeners();
  }

  Future<void> setBudgetId(String newBudgetId) async {
    _budgetId = newBudgetId;
    _transactionService = TransactionService(_database, _currentUserId, _ownerId, _budgetId);
    _favoriteRecordService = FavoriteRecordService(_database, _currentUserId, _ownerId, _budgetId);
    _installmentService = InstallmentService(_database, _currentUserId, _ownerId, _budgetId);

    // 데이터 다시 로드
    await _loadMonthlySummary();
    await loadFavoriteRecords();
    notifyListeners();
  }

  Future<void> syncAllLocalDataToSupabase() async {
    await _assetService.syncAssets();
    await _loadAllAssets();
    await _categoryService.syncCategories();
    await _loadAllCategories();
    await _installmentService.syncInstallments();
    await _favoriteRecordService.syncFavoriteRecords();
    await loadFavoriteRecords();
    await _transactionService.syncTransactions();
    await _loadMonthlySummary();
    await _clearLocalDatabase();
  }

  Future<void> _clearLocalDatabase() async {
    await _database.delete(_database.assets).go();
    await _database.delete(_database.categories).go();
    await _database.insertDefaultCategories();
    await _database.delete(_database.installments).go();
    await _database.delete(_database.favoriteRecords).go();
    await _database.delete(_database.transactions).go();
  }

  // 날짜별 수입/지출 합계 Map 갱신 함수
  void _updateDailySummaryMap() {
    final Map<DateTime, Map<String, int>> summary = {};
    for (final tx in _monthlyTransactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      summary.putIfAbsent(date, () => {'income': 0, 'expense': 0});
      if (tx.type == TransactionType.income) {
        summary[date]!['income'] = summary[date]!['income']! + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        summary[date]!['expense'] = summary[date]!['expense']! + tx.amount;
      }
    }
    _dailySummaryMap = summary;
  }

  // 월 변경 시 거래내역도 새로 로드
  Future<void> changeFocusedDay(DateTime month) async {
    _focusedDay = month;
    // await loadTransactionsForMonth(month);
    await _loadMonthlySummary();
    prefetchSurroundingMonths(month);
    notifyListeners();
  }

  void selectDayAndFocus(DateTime day) {
    _selectedDay = day;
    _focusedDay = day;
    notifyListeners();
  }

  // 🔸 현재 월 거래내역을 로드 (캐시 우선)
  Future<void> _loadMonthlySummary() async {
    final key = _monthKey(_focusedDay);

    if (_monthlyCache.containsKey(key)) {
      _monthlyTransactions = _monthlyCache[key]!;
    } else {
      final transactions = await _fetchTransactionsForMonth(_focusedDay);
      _monthlyCache[key] = transactions;
      _monthlyTransactions = transactions;
      _enforceCacheLimit();
    }

    _monthlyIncome = _monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyExpense = _monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyBalance = _monthlyIncome - _monthlyExpense;
    _updateDailySummaryMap();
  }

  // 🔸 특정 월의 거래내역을 Supabase 또는 Local DB 에서 가져오기
  Future<List<TransactionModel>> _fetchTransactionsForMonth(DateTime targetMonth) async {
    final startDate = DateTime(targetMonth.year, targetMonth.month, 1);
    final endDate = DateTime(targetMonth.year, targetMonth.month + 1, 1);

    if (_currentUserId == null) {
      final query = _database.select(_database.transactions)
        ..where((t) => t.date.isBiggerOrEqualValue(startDate) &
        t.date.isSmallerThanValue(endDate));
      final result = await query.get();
      return result.map(TransactionModel.fromDriftRow).toList();
    } else {
      final response = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('budget_id', _budgetId!)
          .gte('date', startDate.toIso8601String())
          .lt('date', endDate.toIso8601String());
      return response.map(TransactionModel.fromJson).toList();
    }
  }

  // 🔸 주변 월 미리 로드
  Future<void> prefetchSurroundingMonths(DateTime center) async {
    for (int offset = -1; offset <= 1; offset++) {
      final date = DateTime(center.year, center.month + offset, 1);
      final key = _monthKey(date);
      if (!_monthlyCache.containsKey(key)) {
        final data = await _fetchTransactionsForMonth(date);
        _monthlyCache[key] = data;
      }
    }
    _enforceCacheLimit();
  }

  // 🔸 오래된 캐시 제거 (최대 6개월 유지)
  void _enforceCacheLimit() {
    const maxMonths = 3;
    if (_monthlyCache.length > maxMonths) {
      final keys = _monthlyCache.keys.toList()..sort();
      final excess = _monthlyCache.length - maxMonths;
      for (int i = 0; i < excess; i++) {
        _monthlyCache.remove(keys[i]);
      }
    }
  }

  Future<bool> hasAnyTransactions() async {
    return await _transactionService.hasAnyTransactions();
  }

  Future<List<TransactionModel>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    return await _transactionService.getTransactionsByPeriod(start, end);
  }

  Future<void> addTransaction(TransactionModel model) async {
    await _transactionService.addTransaction(model);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> updateTransaction(String id, TransactionModel transaction) async {
    await _transactionService.updateTransaction(id, transaction);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionService.deleteTransaction(id);
    await _loadMonthlySummary();
    notifyListeners();
  }

  // 자산별 월별 수입/지출 합계
  int getIncomeByAsset(String assetId) {
    return _monthlyTransactions
        .where((t) => t.assetId == assetId && t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int getExpenseByAsset(String assetId) {
    return _monthlyTransactions
        .where((t) => t.assetId == assetId && t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // // 카테고리별 기간 내역 조회
  // Future<Map<String?, List<Transaction>>> getTransactionsByCategory(DateTime start, DateTime end) async {
  //   final transactions = await getTransactionsByPeriod(start, end);
  //   final Map<String?, List<Transaction>> categoryTransactions = {};
  //
  //   for (final transaction in transactions) {
  //     categoryTransactions.putIfAbsent(transaction.categoryId, () => []).add(transaction);
  //   }
  //
  //   return categoryTransactions;
  // }

  Future<void> _loadAllCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  Future<List<CategoryModel>> getMainCategories(TransactionType type) async {
    return await _categoryService.getMainCategories(type);
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categoryService.addCategory(category);
    await _loadAllCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoryService.updateCategory(category);
    await _loadAllCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryService.deleteCategory(id);
    await _loadAllCategories();
  }

  Future<void> reorderCategories(List<CategoryModel> reorderedList) async {
    await _categoryService.reorderCategories(reorderedList);
    await _loadAllCategories();
    notifyListeners();
  }

  // 전체 자산 로드
  Future<void> _loadAllAssets() async {
    _assets = await _assetService.getAssets();
    notifyListeners();
  }

  // 자산 추가
  Future<void> addAsset(String name, int targetAmount) async {
    await _assetService.addAsset(name, targetAmount);
    await _loadAllAssets();
  }

  // 자산 수정
  Future<void> updateAsset(String id, String name, int targetAmount) async {
    await _assetService.updateAsset(id, name, targetAmount);
    await _loadAllAssets();
  }

  // 자산 삭제
  Future<void> deleteAsset(String id) async {
    await _assetService.deleteAsset(id);
    await _loadAllAssets();
  }

  Future<List<CategorySummary>> getCategorySummariesByPeriod({
    required DateTime start,
    required DateTime end,
    required TransactionType type,
    required String selectedAssetName,
  }) async {
    if (_currentUserId == null) {
      return _getLocalCategorySummariesByPeriod(start, end, type, selectedAssetName);
    } else {
      return _getSupabaseCategorySummariesByPeriod(start, end, type, selectedAssetName);
    }
  }

  Future<List<CategorySummary>> _getLocalCategorySummariesByPeriod(
    DateTime start,
    DateTime end,
    TransactionType type,
    String selectedAssetName,
  ) async {
    // 자산 ID 찾기 (전체가 아닌 경우)
    String? assetId;
    if (selectedAssetName != '전체') {
      final asset = _assets.firstWhere(
            (a) => a.name == selectedAssetName,
        orElse: () => throw Exception('자산이 존재하지 않습니다: $selectedAssetName'),
      );
      assetId = asset.id;
    }

    // 조인 없이 직접 필터링
    final query = _database.select(_database.transactions).join([
      leftOuterJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.transactions.categoryId),
      ),
    ])
      ..where(_database.transactions.date.isBetweenValues(start, end))
      ..where(_database.transactions.type.equals(type.name)); // enum일 경우 꼭! .name 해주자

    // if (_currentUserId != null) {
    //   query.where(_database.transactions.userId.equals(_currentUserId!));
    // }

    if (assetId != null) {
      query.where(_database.transactions.assetId.equals(assetId));
    }

    // 결과 처리
    final rows = await query.get();

    final Map<String, double> categoryTotals = {};

    for (final row in rows) {
      final tx = row.readTable(_database.transactions);
      final category = row.readTableOrNull(_database.categories);
      final name = category?.name ?? '기타';

      categoryTotals[name] = (categoryTotals[name] ?? 0) + tx.amount.toDouble();
    }

    return categoryTotals.entries.map((e) {
      return CategorySummary(
        name: e.key,
        amount: e.value,
      );
    }).toList();
  }

  Future<List<CategorySummary>> _getSupabaseCategorySummariesByPeriod(
      DateTime start,
      DateTime end,
      TransactionType type,
      String selectedAssetName,
      ) async {
    final client = Supabase.instance.client;
    final ownerId = _ownerId!;
    final budgetId = _budgetId!;

    // 자산 필터링
    String? assetId;
    if (selectedAssetName != '전체') {
      final asset = _assets.firstWhere(
            (a) => a.name == selectedAssetName,
        orElse: () => throw Exception('자산이 존재하지 않습니다: $selectedAssetName'),
      );
      assetId = asset.id;
    }

    final response = client
        .from('transactions')
        .select('amount, category_id, categories(name)')
        .eq('owner_id', ownerId)
        .eq('budget_id', budgetId)
        .eq('type', type.name)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String());

    if (assetId != null) {
      response.eq('asset_id', assetId);
    }

    final raw = await response;

    final Map<String, double> categoryTotals = {};

    for (final row in raw) {
      final categoryName = row['categories']?['name'] ?? '기타';
      final amount = (row['amount'] as num).toDouble();
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
    }

    return categoryTotals.entries.map((e) {
      return CategorySummary(name: e.key, amount: e.value);
    }).toList();
  }


  // 즐겨찾기
  Future<void> loadFavoriteRecords() async {
    _favoriteRecords = await _favoriteRecordService.loadFavoriteRecords();
    notifyListeners();
  }

  Future<void> addFavoriteRecord(FavoriteRecordModel record) async {
    final favoriteRecordNewId = await _favoriteRecordService.addFavoriteRecord(record);
    final modelWithId = record.copyWith(id: favoriteRecordNewId);
    await repeatTransactionService.generateTodayRepeatedTransactions(
      favoriteRecordModel: modelWithId,
    ); // 필요시 유지
    await loadFavoriteRecords();
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> updateFavoriteRecord(String id, FavoriteRecordModel record) async {
    await _favoriteRecordService.updateFavoriteRecord(id, record);
    await loadFavoriteRecords();
  }

  Future<void> deleteFavoriteRecord(String id) async {
    await _favoriteRecordService.deleteFavoriteRecord(id);
    await loadFavoriteRecords();
  }

  // 할부
  Future<void> addInstallment(InstallmentModel installment) async {
    await _installmentService.addInstallment(installment);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> updateInstallment(String id, InstallmentModel installment) async {
    await _installmentService.updateInstallment(id, installment);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> deleteInstallment(String id) async {
    await _installmentService.deleteInstallment(id);
    await _loadMonthlySummary();
    notifyListeners();
  }

  // @override
  // void dispose() {
  //   _categoryService.disposeRealtime();
  //   super.dispose();
  // }
}