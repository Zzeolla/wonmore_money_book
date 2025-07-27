class SubscriptionModel {
  final String? id;
  final String? userId;
  final String? planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;
  final bool? adsEnabled;
  final int? maxBudgets;
  final int? maxSharedUsers;

  SubscriptionModel({
    this.id,
    this.userId,
    this.planName,
    this.startDate,
    this.endDate,
    this.isActive,
    this.adsEnabled,
    this.maxBudgets,
    this.maxSharedUsers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'plan_name': planName,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'ads_enabled': adsEnabled,
      'max_budgets': maxBudgets,
      'max_shared_users': maxSharedUsers,
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['user_id'],
      planName: json['plan_name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'],
      adsEnabled: json['ads_enabled'],
      maxBudgets: json['max_budgets'],
      maxSharedUsers: json['max_shared_users'],
    );
  }

  factory SubscriptionModel.free() => SubscriptionModel(
    planName: 'Free',
    maxBudgets: 3,
    maxSharedUsers: 3,
  );
}