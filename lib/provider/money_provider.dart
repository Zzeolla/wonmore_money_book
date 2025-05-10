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

  MoneyProvider(this._database) {
    _loadMonthlySummary();
  }

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  int get monthlyIncome => _monthlyIncome;
  int get monthlyExpense => _monthlyExpense;
  int get monthlyBalance => _monthlyBalance;

  // 사용자 ID 설정
  void setUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // 월 변경
  Future<void> changeMonth(DateTime month) async {
    _selectedMonth = month;
    await _loadMonthlySummary();
    notifyListeners();
  }

  // 월별 요약 데이터 로드
  Future<void> _loadMonthlySummary() async {
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final query = _database.select(_database.transactions)
      ..where((t) => t.date.isBetweenValues(startDate, endDate));
    
    if (_currentUserId != null) {
      query.where((t) => t.userId.equals(_currentUserId!));
    }

    final transactions = await query.get();
    
    _monthlyIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    _monthlyBalance = _monthlyIncome - _monthlyExpense;
  }

  // 거래 내역 추가
  Future<void> addTransaction(TransactionsCompanion transaction) async {
    final transactionWithUser = transaction.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.transactions).insert(transactionWithUser);
    
    // 추가된 거래가 현재 선택된 월에 속하는 경우에만 요약 업데이트
    if (transaction.date.value.year == _selectedMonth.year &&
        transaction.date.value.month == _selectedMonth.month) {
      await _loadMonthlySummary();
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

      // 수정된 거래가 현재 선택된 월에 속하거나, 이전 거래가 현재 선택된 월에 속한 경우에만 요약 업데이트
      if ((transaction.date.year == _selectedMonth.year &&
           transaction.date.month == _selectedMonth.month) ||
          (oldTransaction.date.year == _selectedMonth.year &&
           oldTransaction.date.month == _selectedMonth.month)) {
        await _loadMonthlySummary();
      }
    }
    notifyListeners();
  }

  // 거래 내역 삭제
  Future<void> deleteTransaction(int id) async {
    final transaction = await (_database.select(_database.transactions)
      ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

    if (transaction != null) {
      await (_database.delete(_database.transactions)
        ..where((t) => t.id.equals(id)))
        .go();

      // 삭제된 거래가 현재 선택된 월에 속한 경우에만 요약 업데이트
      if (transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        await _loadMonthlySummary();
      }
    }
    notifyListeners();
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
  Future<Map<int, List<Transaction>>> getTransactionsByCategory(DateTime start, DateTime end) async {
    final transactions = await getTransactionsByPeriod(start, end);
    final Map<int, List<Transaction>> categoryTransactions = {};
    
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

  // 자산 추가
  Future<void> addAsset(AssetsCompanion asset) async {
    final assetWithUser = asset.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.assets).insert(assetWithUser);
    notifyListeners();
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
    notifyListeners();
  }

  // 자산 삭제
  Future<void> deleteAsset(int id) async {
    await (_database.delete(_database.assets)
      ..where((a) => a.id.equals(id)))
      .go();
    notifyListeners();
  }

  // 카테고리 목록 조회
  Future<List<Category>> getMainCategories(TransactionType type) async {
    return await (_database.select(_database.categories)
      ..where((c) => c.type.equals(type.name)))
      .get();
  }

  // 카테고리 추가
  Future<void> addCategory(CategoriesCompanion category) async {
    final categoryWithUser = category.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.categories).insert(categoryWithUser);
    notifyListeners();
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
    notifyListeners();
  }

  // 카테고리 삭제
  Future<bool> deleteCategory(int id) async {
    return await _database.deleteCategory(id);
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