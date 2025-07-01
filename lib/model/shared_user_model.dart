class SharedUserModel {
  final String? id;
  final String? ownerId;
  final String? userId;

  SharedUserModel({
    this.id,
    this.ownerId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'user_id': userId,
    };
  }

  factory SharedUserModel.fromJson(Map<String, dynamic> json) {
    return SharedUserModel(
      id: json['id'],
      ownerId: json['owner_id'],
      userId: json['user_id'],
    );
  }
}
