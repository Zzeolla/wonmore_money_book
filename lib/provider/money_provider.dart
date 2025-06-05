import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/service/repeat_transaction_service.dart';

class MoneyProvider extends ChangeNotifier {
  final AppDatabase _database;
  late final RepeatTransactionService repeatTransactionService;
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
    notifyListeners();
  }

  // 월별 거래내역 로드        -> 없어도 되는거 아님?
  // Future<void> loadTransactionsForMonth(DateTime month) async {
  //   final startDate = DateTime(month.year, month.month, 1);
  //   final endDate = DateTime(month.year, month.month + 1, 1); // 다음 달 1일로 변경
  //
  //   final query = _database.select(_database.transactions)
  //     ..where((t) => t.date.isBiggerOrEqualValue(startDate) &
  //     t.date.isSmallerThanValue(endDate)); // isBetweenValues 대신 사용
  //   if (_currentUserId != null) {
  //     query.where((t) => t.userId.equals(_currentUserId!));
  //   }
  //
  //   _currentMonthTransactions = await query.get();
  //   _updateDailySummaryMap();
  //   notifyListeners();
  // }

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
    
    if (_currentUserId != null) {
      query.where((t) => t.userId.equals(_currentUserId!));
    }

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

  // 거래 추가/수정/삭제 시 월별 리스트도 갱신
  Future<void> addTransaction(TransactionsCompanion transaction) async {
    final transactionWithUser = transaction.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    final id = await _database.into(_database.transactions).insert(transactionWithUser);
    // 거래 추가 후, 현재 월 거래내역을 DB에서 다시 불러오기!
    // await loadTransactionsForMonth(_focusedDay);
    await _loadMonthlySummary();
    notifyListeners();
  }



  // 거래 내역 수정
  Future<void> updateTransaction(int id, TransactionsCompanion transaction) async {
    await (_database.update(_database.transactions)
      ..where((t) => t.id.equals(id)))
      .write(transaction.copyWith(
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(_currentUserId),
      ));
    // 월이 바뀌었을 수도 있으니 다시 로드
    // await loadTransactionsForMonth(_focusedDay);
    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await (_database.delete(_database.transactions)
      ..where((t) => t.id.equals(id)))
      .go();
    // 삭제 후 다시 로드
    // await loadTransactionsForMonth(_focusedDay);
    await _loadMonthlySummary();
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

  // 기간별 수입/지출 합계 계산
  // Future<({int income, int expense})> getPeriodSummary(DateTime start, DateTime end) async {
  //   final transactions = await getTransactionsByPeriod(start, end);
  //
  //   int income = 0;
  //   int expense = 0;
  //
  //   for (final transaction in transactions) {
  //     if (transaction.type == TransactionType.income) {
  //       income += transaction.amount;
  //     } else if (transaction.type == TransactionType.expense) {
  //       expense += transaction.amount;
  //     }
  //   }
  //
  //   return (income: income, expense: expense);
  // }

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

  Future<void> addAsset(String name, int targetAmount) async {
    final assetWithUser = AssetsCompanion(
    name: Value(name),
    targetAmount: Value(targetAmount),
    userId: Value(_currentUserId),
    createdBy: Value(_currentUserId),
    updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.assets).insert(assetWithUser);
    await _loadAllAssets(); // 자산 목록 새로고침
  }


  // 자산 수정
  Future<void> updateAsset(int id, String name, int targetAmount) async {
    await (_database.update(_database.assets)
      ..where((a) => a.id.equals(id)))
      .write(AssetsCompanion(
        name: Value(name),
        targetAmount: Value(targetAmount),
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
    final query = _database.select(_database.categories)
    ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    if (_currentUserId != null) {
      query.where((c) => c.userId.equals(_currentUserId!));
    }
    _categories = await query.get();
    notifyListeners();
  }

  // 카테고리 추가
  Future<void> addCategory(CategoriesCompanion category) async {
    final nextOrder = await _database.getNextCategorySortOrder(category.type.value);

    final categoryWithUser = category.copyWith(
      sortOrder: Value(nextOrder),
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
  Future<void> deleteCategory(int id) async {
    await (_database.delete(_database.categories)
      ..where((a) => a.id.equals(id)))
        .go();
    await _loadAllCategories(); // 카테고리 목록 새로고침
  }

  Future<void> reorderCategories(List<Category> reorderedList) async {
    await _database.reorderCategories(reorderedList); // database.dart의 reorderCategories 사용
    await _loadAllCategories(); // 변경된 순서 반영 후 전체 새로고침
    notifyListeners();
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

  Future<List<Map<String, dynamic>>> getTransactionsWithCategory(DateTime start, DateTime end) {
    final query = _database.select(_database.transactions)
      ..where((t) => t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);

    final joinQuery = query.join([
      leftOuterJoin(_database.categories, _database.categories.id.equalsExp(_database.transactions.categoryId)),
    ]);

    return joinQuery.map((row) {
      final tx = row.readTable(_database.transactions);
      final category = row.readTableOrNull(_database.categories);

      return {
        'tx': tx,
        'categoryName': category?.name ?? '기타',
      };
    }).get();
  }

  // 전체 즐겨찾기 내역 로드
  Future<void> loadFavoriteRecords() async {
    final query = _database.select(_database.favoriteRecords)
    ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    if (_currentUserId != null) {
      query.where((a) => a.userId.equals(_currentUserId!));
    }
    _favoriteRecords = await query.get();
    notifyListeners();
  }
  
  Future<void> addFavoriteRecord(FavoriteRecordsCompanion record) async {
    final nextOrder = await _database.getNextFavoriteRecordSortOrder(record.period.value);

    final favoriteRecordWithUser = record.copyWith(
      sortOrder: Value(nextOrder),
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );
    await _database.into(_database.favoriteRecords).insert(favoriteRecordWithUser);
    await loadFavoriteRecords();
    await repeatTransactionService.generateTodayRepeatedTransactions();
  }

  Future<void> updateFavoriteRecord(int id, FavoriteRecordsCompanion favoriteRecord) async {
    await (_database.update(_database.favoriteRecords)
      ..where((c) => c.id.equals(id)))
        .write(favoriteRecord.copyWith(
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(_currentUserId),
    ));
    await loadFavoriteRecords();
  }

  Future<void> deleteFavoriteRecord(int id) async {
    await (_database.delete(_database.favoriteRecords)
      ..where((t) => t.id.equals(id)))
        .go();

    await loadFavoriteRecords();
  }

  Future<void> reorderFavoriteRecords(List<FavoriteRecord> reorderedList) async {
    await _database.reorderFavoriteRecords(reorderedList); // database.dart의 reorderCategories 사용
    await loadFavoriteRecords(); // 변경된 순서 반영 후 전체 새로고침
    notifyListeners();
  }


  Future<void> addInstallment(InstallmentsCompanion installment) async {
    final installmentWithUser = installment.copyWith(
      userId: Value(_currentUserId),
      createdBy: Value(_currentUserId),
      updatedBy: Value(_currentUserId),
    );

    final installmentId =
    await _database.into(_database.installments).insert(installmentWithUser);

    await _createTransactionsFromInstallment(installmentId, installmentWithUser);
  }

  Future<void> updateInstallment(int id, InstallmentsCompanion installment) async {
    await _database.delete(_database.transactions)
      ..where((t) => t.installmentId.equals(id))
      ..go();

    await (_database.update(_database.installments)
      ..where((i) => i.id.equals(id)))
        .write(installment.copyWith(
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(_currentUserId),
    ));

    await _createTransactionsFromInstallment(id, installment);
  }

  Future<void> deleteInstallment(int id) async {
    await _database.delete(_database.transactions)
      ..where((t) => t.installmentId.equals(id))
      ..go();

    await (_database.delete(_database.installments)
      ..where((i) => i.id.equals(id)))
        .go();

    await _loadMonthlySummary();
    notifyListeners();
  }

  Future<void> _createTransactionsFromInstallment(int installmentId, InstallmentsCompanion installment) async {
    final months = installment.months.value;
    final totalAmount = installment.totalAmount.value;
    final title = installment.title.value;
    final startDate = installment.date.value;

    final baseAmount = totalAmount ~/ months;
    final remainder = totalAmount % months;

    for (int i = 0; i < months; i++) {
      final amount = i == 0 ? baseAmount + remainder : baseAmount;
      final date = _calculateInstallmentDate(startDate, i);

      await _database.into(_database.transactions).insert(
        TransactionsCompanion(
          date: Value(date),
          amount: Value(amount),
          type: Value(TransactionType.expense),
          categoryId: installment.categoryId,
          assetId: installment.assetId,
          title: Value('$title (${i + 1}/$months)'),
          memo: installment.memo,
          installmentId: Value(installmentId),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          userId: Value(_currentUserId),
          createdBy: Value(_currentUserId),
          updatedBy: Value(_currentUserId),
        ),
      );
    }
    await _loadMonthlySummary();
    notifyListeners();
  }

  DateTime _calculateInstallmentDate(DateTime baseDate, int offset) {
    final year = baseDate.year;
    final month = baseDate.month + offset;
    final tentative = DateTime(year, month, 1, baseDate.hour, baseDate.minute);
    final lastDay = DateTime(tentative.year, tentative.month + 1, 0).day;
    final day = baseDate.day > lastDay ? lastDay : baseDate.day;

    return DateTime(tentative.year, tentative.month, day, baseDate.hour, baseDate.minute);
  }
}