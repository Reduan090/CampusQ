class UserModel {
  final String uid;
  final String email;
  final String role; // 'student' or 'admin'
  final bool isActive;
  final String? name;
  final String? studentId;
  final String? department;
  final String? bloodGroup;
  final String? pictureUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isActive = true,
    this.name,
    this.studentId,
    this.department,
    this.bloodGroup,
    this.pictureUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'isActive': isActive,
      'name': name,
      'studentId': studentId,
      'department': department,
      'bloodGroup': bloodGroup,
      'pictureUrl': pictureUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      isActive: map['isActive'] as bool? ?? true,
      name: map['name'] as String?,
      studentId: map['studentId'] as String?,
      department: map['department'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      pictureUrl: map['pictureUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    bool? isActive,
    String? name,
    String? studentId,
    String? department,
    String? bloodGroup,
    String? pictureUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
