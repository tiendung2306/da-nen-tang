package com.smartgrocery.service

import com.smartgrocery.dto.admin.*
import com.smartgrocery.dto.common.PageResponse
import com.smartgrocery.entity.User
import com.smartgrocery.exception.*
import com.smartgrocery.repository.*
import com.smartgrocery.security.CustomUserDetails
import org.springframework.data.domain.Pageable
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AdminService(
    private val userRepository: UserRepository,
    private val roleRepository: RoleRepository,
    private val categoryRepository: CategoryRepository,
    private val masterProductRepository: MasterProductRepository,
    private val familyRepository: FamilyRepository,
    private val passwordEncoder: PasswordEncoder
) {

    // ============================================
    // USER MANAGEMENT
    // ============================================

    fun getAllUsers(pageable: Pageable): PageResponse<AdminUserResponse> {
        val usersPage = userRepository.findAll(pageable)

        return PageResponse(
            content = usersPage.content.map { toAdminUserResponse(it) },
            page = usersPage.number,
            size = usersPage.size,
            totalElements = usersPage.totalElements,
            totalPages = usersPage.totalPages,
            first = usersPage.isFirst,
            last = usersPage.isLast
        )
    }

    fun getUserById(userId: Long): AdminUserDetailResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        return toAdminUserDetailResponse(user)
    }

    fun searchUsers(keyword: String, pageable: Pageable): PageResponse<AdminUserResponse> {
        val pattern = "%${keyword.lowercase()}%"
        val usersPage = userRepository.searchUsersAdvanced(
            pattern = pattern,
            exactKeyword = keyword,
            excludeUserId = -1, // Don't exclude any user for admin search
            pageable = pageable
        )

        return PageResponse(
            content = usersPage.content.map { toAdminUserResponse(it) },
            page = usersPage.number,
            size = usersPage.size,
            totalElements = usersPage.totalElements,
            totalPages = usersPage.totalPages,
            first = usersPage.isFirst,
            last = usersPage.isLast
        )
    }

    @Transactional
    fun createUser(request: AdminCreateUserRequest): AdminUserResponse {
        // Check if username exists
        if (userRepository.existsByUsername(request.username)) {
            throw ConflictException(ErrorCode.USERNAME_ALREADY_EXISTS)
        }

        // Check if email exists
        if (userRepository.existsByEmail(request.email)) {
            throw ConflictException(ErrorCode.EMAIL_ALREADY_EXISTS)
        }

        // Get roles
        val roles = request.roleNames.map { roleName ->
            roleRepository.findByName(roleName)
                ?: throw ApiException(ErrorCode.ROLE_NOT_FOUND, "Role '$roleName' not found")
        }.toMutableSet()

        if (roles.isEmpty()) {
            throw ApiException(ErrorCode.MUST_HAVE_AT_LEAST_ONE_ROLE)
        }

        val user = User(
            username = request.username,
            email = request.email,
            passwordHash = passwordEncoder.encode(request.password),
            fullName = request.fullName,
            roles = roles
        )

        val savedUser = userRepository.save(user)
        return toAdminUserResponse(savedUser)
    }

    @Transactional
    fun updateUser(userId: Long, request: AdminUpdateUserRequest): AdminUserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        request.fullName?.let { user.fullName = it }
        request.email?.let { newEmail ->
            if (newEmail != user.email && userRepository.existsByEmail(newEmail)) {
                throw ConflictException(ErrorCode.EMAIL_ALREADY_EXISTS)
            }
            user.email = newEmail
        }

        val savedUser = userRepository.save(user)
        return toAdminUserResponse(savedUser)
    }

    @Transactional
    fun updateUserStatus(userId: Long, request: UpdateUserStatusRequest): AdminUserResponse {
        val currentUserId = getCurrentUserId()

        // Cannot deactivate self
        if (userId == currentUserId && !request.isActive) {
            throw ApiException(ErrorCode.CANNOT_DEACTIVATE_SELF)
        }

        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        user.isActive = request.isActive

        val savedUser = userRepository.save(user)
        return toAdminUserResponse(savedUser)
    }

    @Transactional
    fun updateUserRoles(userId: Long, request: UpdateUserRolesRequest): AdminUserResponse {
        val currentUserId = getCurrentUserId()

        if (request.roleNames.isEmpty()) {
            throw ApiException(ErrorCode.MUST_HAVE_AT_LEAST_ONE_ROLE)
        }

        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        // Check if trying to remove ADMIN role from self
        val currentUserIsTarget = userId == currentUserId
        val hadAdminRole = user.roles.any { it.name == "ADMIN" }
        val willHaveAdminRole = request.roleNames.contains("ADMIN")

        if (currentUserIsTarget && hadAdminRole && !willHaveAdminRole) {
            throw ApiException(ErrorCode.CANNOT_REMOVE_OWN_ADMIN)
        }

        // Get new roles
        val newRoles = request.roleNames.map { roleName ->
            roleRepository.findByName(roleName)
                ?: throw ApiException(ErrorCode.ROLE_NOT_FOUND, "Role '$roleName' not found")
        }.toMutableSet()

        user.roles.clear()
        user.roles.addAll(newRoles)

        val savedUser = userRepository.save(user)
        return toAdminUserResponse(savedUser)
    }

    @Transactional
    fun deleteUser(userId: Long) {
        val currentUserId = getCurrentUserId()

        // Cannot delete self
        if (userId == currentUserId) {
            throw ApiException(ErrorCode.CANNOT_DELETE_SELF)
        }

        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        // Check if this is the last admin
        if (user.roles.any { it.name == "ADMIN" }) {
            val adminCount = userRepository.findAll().count { u ->
                u.roles.any { it.name == "ADMIN" }
            }
            if (adminCount <= 1) {
                throw ApiException(ErrorCode.CANNOT_DELETE_LAST_ADMIN)
            }
        }

        userRepository.delete(user)
    }

    @Transactional
    fun resetUserPassword(userId: Long, newPassword: String): AdminUserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        user.passwordHash = passwordEncoder.encode(newPassword)

        val savedUser = userRepository.save(user)
        return toAdminUserResponse(savedUser)
    }

    // ============================================
    // STATISTICS
    // ============================================

    fun getStats(): AdminStatsResponse {
        val allUsers = userRepository.findAll()

        return AdminStatsResponse(
            totalUsers = allUsers.size.toLong(),
            activeUsers = allUsers.count { it.isActive }.toLong(),
            inactiveUsers = allUsers.count { !it.isActive }.toLong(),
            totalCategories = categoryRepository.count(),
            totalProducts = masterProductRepository.count(),
            totalFamilies = familyRepository.count()
        )
    }

    // ============================================
    // ROLE MANAGEMENT
    // ============================================

    fun getAllRoles(): List<RoleResponse> {
        return roleRepository.findAll().map { role ->
            RoleResponse(
                id = role.id!!,
                name = role.name,
                description = role.description
            )
        }
    }

    // ============================================
    // HELPER METHODS
    // ============================================

    private fun getCurrentUserId(): Long {
        val authentication = SecurityContextHolder.getContext().authentication
        val userDetails = authentication.principal as CustomUserDetails
        return userDetails.id
    }

    private fun toAdminUserResponse(user: User): AdminUserResponse {
        return AdminUserResponse(
            id = user.id!!,
            username = user.username,
            email = user.email,
            fullName = user.fullName,
            avatarUrl = user.avatarUrl?.let { "/files/$it" },
            isActive = user.isActive,
            roles = user.roles.map { it.name },
            createdAt = user.createdAt,
            updatedAt = user.updatedAt
        )
    }

    private fun toAdminUserDetailResponse(user: User): AdminUserDetailResponse {
        return AdminUserDetailResponse(
            id = user.id!!,
            username = user.username,
            email = user.email,
            fullName = user.fullName,
            avatarUrl = user.avatarUrl?.let { "/files/$it" },
            isActive = user.isActive,
            roles = user.roles.map { role ->
                RoleResponse(
                    id = role.id!!,
                    name = role.name,
                    description = role.description
                )
            },
            fcmToken = user.fcmToken,
            createdAt = user.createdAt,
            updatedAt = user.updatedAt
        )
    }
}

