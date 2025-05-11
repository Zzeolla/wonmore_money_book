import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class MoneyProvider extends ChangeNotifier {
  final AppDatabase _database;
  String? _currentUserId;
  DateTime _selectedMonth = DateTime.now();
  int _monthlyIncome = 0;
  int _monthlyExpense = 0;
  int _monthlyBalance = 0;
  
  // 카테고리 상태 관리 추가
  List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  // 자산 상태 관리 추가
  List<Asset> _assets = [];
  List<Asset> get assets => _assets;
  
  // 수입/지출 카테고리 getter
  List<Category> getIncomeCategories() => _categories.where((c) => c.type == TransactionType.income).toList();
  List<Category> getExpenseCategories() => _categories.where((c) => c.type == TransactionType.expense).toList();
  List<Category> getTransferCategories() => _categories.where((c) => c.type == TransactionType.transfer).toList();

  // 월별 거래내역 캐시 관리
  final Map<String, List<Transaction>> _monthlyTransactions = {};
  static const int _maxCachedMonths = 3;
  
  // 현재 월의 거래내역 getter
  List<Transaction> get currentMonthTransactions => 
    _monthlyTransactions[_getMonthKey(_selectedMonth)] ?? [];

  MoneyProvider(this._database) {
    _loadMonthlySummary();
    _loadAllCategories(); // 앱 시작 시 전체 카테고리 로드
    _loadAllAssets(); // 앱 시작 시 전체 자산 로드
  }

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  int get monthlyIncome => _monthlyIncome;
  int get monthlyExpense => _monthlyExpense;
  int get monthlyBalance => _monthlyBalance;

  // 월 키 생성 (예: "2024-05")
  String _getMonthKey(DateTime date) => 
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

  // 캐시된 월 정리
  void _cleanupCache() {
    if (_monthlyTransactions.length > _maxCachedMonths) {
      final sortedKeys = _monthlyTransactions.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // 최신순 정렬
      
      // 최신 3개월만 유지
      for (var i = _maxCachedMonths; i < sortedKeys.length; i++) {
        _monthlyTransactions.remove(sortedKeys[i]);
      }
    }
  }

  // 사용자 ID 설정
  void setUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // 월별 거래내역 로드
  Future<void> loadTransactionsForMonth(DateTime month) async {
    final monthKey = _getMonthKey(month);
    
    // 이미 로드된 월이면 캐시된 데이터 사용
    if (_monthlyTransactions.containsKey(monthKey)) {
      _selectedMonth = month;
      notifyListeners();
      return;
    }

    // 새로운 월이면 DB에서 로드
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final query = _database.select(_database.transactions)
      ..where((t) => t.date.isBetweenValues(startDate, endDate));
    if (_currentUserId != null) {
      query.where((t) => t.userId.equals(_currentUserId!));
    }
    
    final transactions = await query.get();
    _monthlyTransactions[monthKey] = transactions;
    _cleanupCache(); // 캐시 정리
    _selectedMonth = month;
    notifyListeners();
  }

  // 월 변경 시 거래내역도 새로 로드
  Future<void> changeMonth(DateTime month) async {
    await loadTransactionsForMonth(month);
    await _loadMonthlySummary();
  }

  // 월별 요약 데이터 로드
  Future<void> _loadMonthlySummary() async {
    final monthKey = _getMonthKey(_selectedMonth);
    final transactions = _monthlyTransactions[monthKey] ?? [];
    
    _monthlyIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyBalance = _monthlyIncome - _monthlyExpense;
    notifyListeners();
  }

  // 거래 추가/수정/삭제 시 월별 리스트도 갱신
  Future<void> addTransaction(TransactionsCompanion transaction) async {
    final transactionWithUser = transaction.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    final id = await _database.into(_database.transactions).insert(transactionWithUser);
    final tx = await (_database.select(_database.transactions)..where((t) => t.id.equals(id))).getSingle();
    
    // 해당 월의 캐시에 추가
    final monthKey = _getMonthKey(tx.date);
    if (_monthlyTransactions.containsKey(monthKey)) {
      _monthlyTransactions[monthKey]!.add(tx);
      if (monthKey == _getMonthKey(_selectedMonth)) {
        await _loadMonthlySummary();
      }
    }
    notifyListeners();
  }

  // 거래 내역 수정
  Future<void> updateTransaction(Transaction transaction) async {
    final oldTransaction = await (_database.select(_database.transactions)
      ..where((t) => t.id.equals(transaction.id)))
      .getSingleOrNull();
      
    if (oldTransaction != null) {
      await (_database.update(_database.transactions)
        ..where((t) => t.id.equals(transaction.id)))
        .write(TransactionsCompanion(
          date: Value(transaction.date),
          amount: Value(transaction.amount),
          type: Value(transaction.type),
          categoryId: Value(transaction.categoryId),
          assetId: Value(transaction.assetId),
          title: Value(transaction.title),
          memo: Value(transaction.memo),
          updatedAt: Value(DateTime.now()),
          updatedBy: Value(_currentUserId),
        ));

      // 캐시 업데이트
      final oldMonthKey = _getMonthKey(oldTransaction.date);
      final newMonthKey = _getMonthKey(transaction.date);
      
      if (_monthlyTransactions.containsKey(oldMonthKey)) {
        _monthlyTransactions[oldMonthKey]!.removeWhere((t) => t.id == transaction.id);
      }
      
      if (_monthlyTransactions.containsKey(newMonthKey)) {
        _monthlyTransactions[newMonthKey]!.add(transaction);
      }
      
      await _loadMonthlySummary();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    // 삭제할 거래 찾기
    Transaction? transactionToDelete;
    String? monthKey;
    
    for (final key in _monthlyTransactions.keys) {
      final tx = _monthlyTransactions[key]!.firstWhere(
        (t) => t.id == id,
        orElse: () => null as Transaction,
      );
      if (tx != null) {
        transactionToDelete = tx;
        monthKey = key;
        break;
      }
    }

    if (transactionToDelete != null) {
      await (_database.delete(_database.transactions)
        ..where((t) => t.id.equals(id)))
        .go();
        
      // 캐시에서 제거
      if (monthKey != null && _monthlyTransactions.containsKey(monthKey)) {
        _monthlyTransactions[monthKey]!.removeWhere((t) => t.id == id);
        await _loadMonthlySummary();
        notifyListeners();
      }
    }
  }

  // 기간별 거래 내역 조회
  Future<List<Transaction>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    final query = _database.select(_database.transactions)
      ..where((t) => t.date.isBetweenValues(start, end));
    
    if (_currentUserId != null) {
      query.where((t) => t.userId.equals(_currentUserId!));
    }
    
    return await query.get();
  }

  // 기간별 수입/지출 합계 계산
  Future<({int income, int expense})> getPeriodSummary(DateTime start, DateTime end) async {
    final transactions = await getTransactionsByPeriod(start, end);
    
    int income = 0;
    int expense = 0;
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        expense += transaction.amount;
      }
    }
    
    return (income: income, expense: expense);
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

  // 자산 목록 조회
  Future<List<Asset>> getAssets() async {
    final query = _database.select(_database.assets);
    if (_currentUserId != null) {
      query.where((a) => a.userId.equals(_currentUserId!));
    }
    return await query.get();
  }

  // 전체 자산 로드
  Future<void> _loadAllAssets() async {
    final query = _database.select(_database.assets);
    if (_currentUserId != null) {
      query.where((a) => a.userId.equals(_currentUserId!));
    }
    _assets = await query.get();
    notifyListeners();
  }

  // 자산 추가
  Future<void> addAsset(AssetsCompanion asset) async {
    final assetWithUser = asset.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.assets).insert(assetWithUser);
    await _loadAllAssets(); // 자산 목록 새로고침
  }

  // 자산 수정
  Future<void> updateAsset(Asset asset) async {
    await (_database.update(_database.assets)
      ..where((a) => a.id.equals(asset.id)))
      .write(AssetsCompanion(
        name: Value(asset.name),
        balance: Value(asset.balance),
        goalAmount: Value(asset.goalAmount),
        type: Value(asset.type),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(_currentUserId),
      ));
    await _loadAllAssets(); // 자산 목록 새로고침
  }

  // 자산 삭제
  Future<void> deleteAsset(int id) async {
    await (_database.delete(_database.assets)
      ..where((a) => a.id.equals(id)))
      .go();
    await _loadAllAssets(); // 자산 목록 새로고침
  }

  // 카테고리 목록 조회
  Future<List<Category>> getMainCategories(TransactionType type) async {
    return await (_database.select(_database.categories)
      ..where((c) => c.type.equals(type.name)))
      .get();
  }

  // 전체 카테고리 로드
  Future<void> _loadAllCategories() async {
    final query = _database.select(_database.categories);
    if (_currentUserId != null) {
      query.where((c) => c.userId.equals(_currentUserId!));
    }
    _categories = await query.get();
    notifyListeners();
  }

  // 카테고리 추가
  Future<void> addCategory(CategoriesCompanion category) async {
    final categoryWithUser = category.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.categories).insert(categoryWithUser);
    await _loadAllCategories(); // 카테고리 목록 새로고침
  }

  // 카테고리 수정
  Future<void> updateCategory(Category category) async {
    await (_database.update(_database.categories)
      ..where((c) => c.id.equals(category.id)))
      .write(CategoriesCompanion(
        name: Value(category.name),
        type: Value(category.type),
        iconName: Value(category.iconName),
        colorValue: Value(category.colorValue),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(_currentUserId),
      ));
    await _loadAllCategories(); // 카테고리 목록 새로고침
  }

  // 카테고리 삭제
  Future<bool> deleteCategory(int id) async {
    final result = await _database.deleteCategory(id);
    if (result) {
      await _loadAllCategories(); // 카테고리 목록 새로고침
    }
    return result;
  }

  // 특정 날짜의 거래 내역 조회
  Future<List<Transaction>> getTransactionsByDate(DateTime date) async {
    final query = _database.select(_database.transactions)
      ..where((t) => t.date.equals(date));
    
    if (_currentUserId != null) {
      query.where((t) => t.userId.equals(_currentUserId!));
    }
    
    return await query.get();
  }
} 