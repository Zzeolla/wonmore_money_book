import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/category_summary.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/asset_service.dart';
import 'package:wonmore_money_book/provider/money/category_service.dart';
import 'package:wonmore_money_book/provider/money/favorite_record_service.dart';
import 'package:wonmore_money_book/provider/money/installment_service.dart';
import 'package:wonmore_money_book/provider/money/transaction_service.dart';
import 'package:wonmore_money_book/service/repeat_transaction_service.dart';

class MoneyProvider extends ChangeNotifier {
  final AppDatabase _database;
  late final RepeatTransactionService repeatTransactionService;
  late TransactionService _transactionService;
  late CategoryService _categoryService;
  late AssetService _assetService;
  late FavoriteRecordService _favoriteRecordService;
  late InstallmentService _installmentService;
  String? _currentUserId;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _monthlyIncome = 0;
  int _monthlyExpense = 0;
  int _monthlyBalance = 0;

  AppDatabase get database => _database;
  
  // 카테고리 상태 관리 추가
  List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  // 자산 상태 관리 추가
  List<Asset> _assets = [];
  List<Asset> get assets => _assets;

  // 즐겨찾기 거래내역 상태 관리 추가
  List<FavoriteRecord> _favoriteRecords = [];
  List<FavoriteRecord> get favoriteRecords => _favoriteRecords;

  // // 즐겨찾기 거래내역 상태 관리 추가
  // List<Installment> _installments = [];
  // List<Installment> get installments => _installments;
  
  // 수입/지출 카테고리 getter
  List<Category> getIncomeCategories() => _categories.where((c) => c.type == TransactionType.income).toList();
  List<Category> getExpenseCategories() => _categories.where((c) => c.type == TransactionType.expense).toList();
  List<Category> getTransferCategories() => _categories.where((c) => c.type == TransactionType.transfer).toList();

  // 월별 거래내역 상태 관리
  List<Transaction> _monthlyTransactions = [];
  List<Transaction> get monthlyTransactions => _monthlyTransactions;

  // 날짜별 수입/지출 합계 상태 관리 추가
  Map<DateTime, Map<String, int>> _dailySummaryMap = {};
  Map<DateTime, Map<String, int>> get dailySummaryMap => _dailySummaryMap;

  MoneyProvider(this._database) {
    _transactionService = TransactionService(_database, _currentUserId);
    _categoryService = CategoryService(_database, _currentUserId);
    _assetService = AssetService(_database, _currentUserId);
    _favoriteRecordService = FavoriteRecordService(_database, _currentUserId);
    _installmentService = InstallmentService(_database, _currentUserId);
    repeatTransactionService = RepeatTransactionService(this);

    _loadMonthlySummary();
    _loadAllCategories(); // 앱 시작 시 전체 카테고리 로드
    _loadAllAssets(); // 앱 시작 시 전체 자산 로드
    loadFavoriteRecords();
  }

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  int get monthlyIncome => _monthlyIncome;
  int get monthlyExpense => _monthlyExpense;
  int get monthlyBalance => _monthlyBalance;

  // 사용자 ID 설정
  void setUserId(String userId) {
    _currentUserId = userId;
    _transactionService = TransactionService(_database, _currentUserId);
    _categoryService = CategoryService(_database, _currentUserId);
    _assetService = AssetService(_database, _currentUserId);
    _favoriteRecordService = FavoriteRecordService(_database, _currentUserId);
    _installmentService = InstallmentService(_database, _currentUserId);
    notifyListeners();
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
    notifyListeners();
  }

  void selectDayAndFocus(DateTime day) {
    _selectedDay = day;
    _focusedDay = day;
    notifyListeners();
  }

  // 월별 요약 데이터 로드
  Future<void> _loadMonthlySummary() async {
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

    final query = _database.select(_database.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(startDate) &
      t.date.isSmallerThanValue(endDate));
    
    // if (_currentUserId != null) {
    //   query.where((t) => t.userId.equals(_currentUserId!));
    // }

    _monthlyTransactions = await query.get();
    
    _monthlyIncome = _monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyExpense = _monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyBalance = _monthlyIncome - _monthlyExpense;
    _updateDailySummaryMap();
  }

  Future<bool> hasAnyTransactions() async {
    return await _transactionService.hasAnyTransactions();
  }

  Future<List<Transaction>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    return await _transactionService.getTransactionsByPeriod(start, end);
  }

  Future<void> addTransaction(TransactionsCompanion transaction) async {
    await _transactionService.addTransaction(transaction);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> updateTransaction(int id, TransactionsCompanion transaction) async {
    await _transactionService.updateTransaction(id, transaction);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _transactionService.deleteTransaction(id);
    await _loadMonthlySummary();
    notifyListeners();
  }

  // 자산별 월별 수입/지출 합계
  int getIncomeByAsset(int assetId) {
    return _monthlyTransactions
        .where((t) => t.assetId == assetId && t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int getExpenseByAsset(int assetId) {
    return _monthlyTransactions
        .where((t) => t.assetId == assetId && t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // 카테고리별 기간 내역 조회
  Future<Map<int?, List<Transaction>>> getTransactionsByCategory(DateTime start, DateTime end) async {
    final transactions = await getTransactionsByPeriod(start, end);
    final Map<int?, List<Transaction>> categoryTransactions = {};
    
    for (final transaction in transactions) {
      categoryTransactions.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }
    
    return categoryTransactions;
  }

  Future<void> _loadAllCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  Future<List<Category>> getMainCategories(TransactionType type) async {
    return await _categoryService.getMainCategories(type);
  }

  Future<void> addCategory(CategoriesCompanion category) async {
    await _categoryService.addCategory(category);
    await _loadAllCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _categoryService.updateCategory(category);
    await _loadAllCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryService.deleteCategory(id);
    await _loadAllCategories();
  }

  Future<void> reorderCategories(List<Category> reorderedList) async {
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
  Future<void> updateAsset(int id, String name, int targetAmount) async {
    await _assetService.updateAsset(id, name, targetAmount);
    await _loadAllAssets();
  }

  // 자산 삭제
  Future<void> deleteAsset(int id) async {
    await _assetService.deleteAsset(id);
    await _loadAllAssets();
  }

  Future<List<CategorySummary>> getCategorySummariesByPeriod({
    required DateTime start,
    required DateTime end,
    required TransactionType type,
    required String selectedAssetName,
  }) async {
    // 자산 ID 찾기 (전체가 아닌 경우)
    int? assetId;
    if (selectedAssetName != '전체') {
      final asset = _assets.firstWhere(
            (a) => a.name == selectedAssetName,
        orElse: () => throw Exception('자산 이름이 존재하지 않습니다: $selectedAssetName'),
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

  // 즐겨찾기
  Future<void> loadFavoriteRecords() async {
    _favoriteRecords = await _favoriteRecordService.loadFavoriteRecords();
    notifyListeners();
  }

  Future<void> addFavoriteRecord(FavoriteRecordsCompanion record) async {
    await _favoriteRecordService.addFavoriteRecord(record);
    await loadFavoriteRecords();
    await repeatTransactionService.generateTodayRepeatedTransactions(); // 필요시 유지
  }

  Future<void> updateFavoriteRecord(int id, FavoriteRecordsCompanion record) async {
    await _favoriteRecordService.updateFavoriteRecord(id, record);
    await loadFavoriteRecords();
  }

  Future<void> deleteFavoriteRecord(int id) async {
    await _favoriteRecordService.deleteFavoriteRecord(id);
    await loadFavoriteRecords();
  }

  // 할부
  Future<void> addInstallment(InstallmentsCompanion installment) async {
    await _installmentService.addInstallment(installment);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> updateInstallment(int id, InstallmentsCompanion installment) async {
    await _installmentService.updateInstallment(id, installment);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> deleteInstallment(int id) async {
    await _installmentService.deleteInstallment(id);
    await _loadMonthlySummary();
    notifyListeners();
  }
}