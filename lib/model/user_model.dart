class UserModel {
  String? id;
  String? email;
  String? name;
  String? groupName;
  String? lastOwnerId;
  String? lastBudgetId;
  bool? isProfile;
  String? profileUrl;

  UserModel({
    this.id,
    this.email,
    this.name,
    this.groupName,
    this.lastOwnerId,
    this.lastBudgetId,
    this.isProfile,
    this.profileUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'group_name': groupName,
      'last_owner_id': lastOwnerId,
      'last_budget_id': lastBudgetId,
      'is_profile': isProfile,
      'profile_url': profileUrl
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      groupName: json['group_name'],
      lastOwnerId: json['last_owner_id'],
      lastBudgetId: json['last_budget_id'],
      isProfile: json['is_profile'],
      profileUrl: json['profile_url'],
    );
  }
}