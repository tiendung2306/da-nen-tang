class AdminUser {
  final int? id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final bool? isActive;
  final List<AdminRole>? roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUser({
    this.id,
    this.username,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.isActive,
    this.roles,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    // Parse roles - handle both string and map formats
    List<AdminRole>? parseRoles(dynamic rolesData) {
      if (rolesData == null) return null;

      return (rolesData as List)
          .map((role) {
            if (role is String) {
              // If role is a string, create AdminRole with just the name
              return AdminRole(name: role);
            } else if (role is Map<String, dynamic>) {
              // If role is a map, parse it normally
              return AdminRole.fromJson(role);
            }
            return null;
          })
          .whereType<AdminRole>()
          .toList();
    }

    return AdminUser(
      id: json['id'] as int?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool?,
      roles: parseRoles(json['roles']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'roles': roles?.map((role) => role.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, username: $username, email: $email, fullName: $fullName, isActive: $isActive)';
  }
}

class AdminRole {
  final String? name;
  final String? description;

  AdminRole({
    this.name,
    this.description,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }

  @override
  String toString() => 'AdminRole(name: $name)';
}

class AdminStats {
  final int? totalUsers;
  final int? activeUsers;
  final int? inactiveUsers;
  final int? adminCount;
  final int? userCount;
  final Map<String, int>? roleCounts;

  AdminStats({
    this.totalUsers,
    this.activeUsers,
    this.inactiveUsers,
    this.adminCount,
    this.userCount,
    this.roleCounts,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] as int?,
      activeUsers: json['activeUsers'] as int?,
      inactiveUsers: json['inactiveUsers'] as int?,
      adminCount: json['adminCount'] as int?,
      userCount: json['userCount'] as int?,
      roleCounts: json['roleCounts'] != null
          ? Map<String, int>.from(json['roleCounts'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'adminCount': adminCount,
      'userCount': userCount,
      'roleCounts': roleCounts,
    };
  }

  @override
  String toString() {
    return 'AdminStats(totalUsers: $totalUsers, activeUsers: $activeUsers, inactiveUsers: $inactiveUsers)';
  }
}
