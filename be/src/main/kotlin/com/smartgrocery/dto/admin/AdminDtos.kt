package com.smartgrocery.dto.admin

import java.time.Instant

// ============================================
// REQUEST DTOs
// ============================================

data class UpdateUserStatusRequest(
    val isActive: Boolean
)

data class UpdateUserRolesRequest(
    val roleNames: List<String>  // e.g., ["USER", "ADMIN"]
)

data class AdminCreateUserRequest(
    val username: String,
    val email: String,
    val password: String,
    val fullName: String,
    val roleNames: List<String> = listOf("USER")
)

data class AdminUpdateUserRequest(
    val fullName: String? = null,
    val email: String? = null
)

// ============================================
// RESPONSE DTOs
// ============================================

data class AdminUserResponse(
    val id: Long,
    val username: String,
    val email: String,
    val fullName: String,
    val avatarUrl: String?,
    val isActive: Boolean,
    val roles: List<String>,
    val createdAt: Instant,
    val updatedAt: Instant
)

data class AdminUserDetailResponse(
    val id: Long,
    val username: String,
    val email: String,
    val fullName: String,
    val avatarUrl: String?,
    val isActive: Boolean,
    val roles: List<RoleResponse>,
    val fcmToken: String?,
    val createdAt: Instant,
    val updatedAt: Instant
)

data class RoleResponse(
    val id: Long,
    val name: String,
    val description: String?
)

data class AdminStatsResponse(
    val totalUsers: Long,
    val activeUsers: Long,
    val inactiveUsers: Long,
    val totalCategories: Long,
    val totalProducts: Long,
    val totalFamilies: Long
)

