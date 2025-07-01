// 거래 유형 enum
enum TransactionType {
  income,   // 수입
  expense,  // 지출
  transfer  // 이체
}

extension TransactionTypeExtension on TransactionType {
  String get asString => name;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => TransactionType.expense, // 기본값
    );
  }
}