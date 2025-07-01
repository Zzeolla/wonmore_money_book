class BudgetModel {
  final String? id;
  final String? ownerId;
  final String? name;
  final bool? isMain;

  BudgetModel({
    this.id,
    this.ownerId,
    this.name,
    this.isMain,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'is_main': isMain,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      isMain: json['is_main'],
    );
  }
}
