package com.smartgrocery.controller

import com.smartgrocery.dto.admin.*
import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.common.PageResponse
import com.smartgrocery.service.AdminService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/admin")
@Tag(name = "Admin", description = "Admin management APIs (ADMIN role required)")
class AdminController(
    private val adminService: AdminService
) {

    // ============================================
    // USER MANAGEMENT
    // ============================================

    @GetMapping("/users")
    @Operation(summary = "Get all users with pagination")
    fun getAllUsers(
        @PageableDefault(size = 20, sort = ["createdAt"], direction = Sort.Direction.DESC) pageable: Pageable
    ): ResponseEntity<ApiResponse<PageResponse<AdminUserResponse>>> {
        val users = adminService.getAllUsers(pageable)
        return ResponseEntity.ok(ApiResponse.success(users))
    }

    @GetMapping("/users/{id}")
    @Operation(summary = "Get user details by ID")
    fun getUserById(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<AdminUserDetailResponse>> {
        val user = adminService.getUserById(id)
        return ResponseEntity.ok(ApiResponse.success(user))
    }

    @GetMapping("/users/search")
    @Operation(summary = "Search users by keyword (username, email, fullName)")
    fun searchUsers(
        @RequestParam keyword: String,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<PageResponse<AdminUserResponse>>> {
        val users = adminService.searchUsers(keyword, pageable)
        return ResponseEntity.ok(ApiResponse.success(users))
    }

    @PostMapping("/users")
    @Operation(summary = "Create a new user")
    fun createUser(
        @Valid @RequestBody request: AdminCreateUserRequest
    ): ResponseEntity<ApiResponse<AdminUserResponse>> {
        val user = adminService.createUser(request)
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.created(user, "User created successfully"))
    }

    @PutMapping("/users/{id}")
    @Operation(summary = "Update user information")
    fun updateUser(
        @PathVariable id: Long,
        @Valid @RequestBody request: AdminUpdateUserRequest
    ): ResponseEntity<ApiResponse<AdminUserResponse>> {
        val user = adminService.updateUser(id, request)
        return ResponseEntity.ok(ApiResponse.success(user, "User updated successfully"))
    }

    @PatchMapping("/users/{id}/status")
    @Operation(summary = "Activate or deactivate a user")
    fun updateUserStatus(
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdateUserStatusRequest
    ): ResponseEntity<ApiResponse<AdminUserResponse>> {
        val user = adminService.updateUserStatus(id, request)
        val message = if (request.isActive) "User activated successfully" else "User deactivated successfully"
        return ResponseEntity.ok(ApiResponse.success(user, message))
    }

    @PatchMapping("/users/{id}/roles")
    @Operation(summary = "Update user roles")
    fun updateUserRoles(
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdateUserRolesRequest
    ): ResponseEntity<ApiResponse<AdminUserResponse>> {
        val user = adminService.updateUserRoles(id, request)
        return ResponseEntity.ok(ApiResponse.success(user, "User roles updated successfully"))
    }

    @PostMapping("/users/{id}/reset-password")
    @Operation(summary = "Reset user password")
    fun resetUserPassword(
        @PathVariable id: Long,
        @RequestBody request: Map<String, String>
    ): ResponseEntity<ApiResponse<AdminUserResponse>> {
        val newPassword = request["newPassword"]
            ?: throw com.smartgrocery.exception.ValidationException("newPassword is required")

        val user = adminService.resetUserPassword(id, newPassword)
        return ResponseEntity.ok(ApiResponse.success(user, "Password reset successfully"))
    }

    @DeleteMapping("/users/{id}")
    @Operation(summary = "Delete a user")
    fun deleteUser(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        adminService.deleteUser(id)
        return ResponseEntity.ok(ApiResponse.success("User deleted successfully"))
    }

    // ============================================
    // STATISTICS
    // ============================================

    @GetMapping("/stats")
    @Operation(summary = "Get system statistics")
    fun getStats(): ResponseEntity<ApiResponse<AdminStatsResponse>> {
        val stats = adminService.getStats()
        return ResponseEntity.ok(ApiResponse.success(stats))
    }

    // ============================================
    // ROLE MANAGEMENT
    // ============================================

    @GetMapping("/roles")
    @Operation(summary = "Get all available roles")
    fun getAllRoles(): ResponseEntity<ApiResponse<List<RoleResponse>>> {
        val roles = adminService.getAllRoles()
        return ResponseEntity.ok(ApiResponse.success(roles))
    }
}

