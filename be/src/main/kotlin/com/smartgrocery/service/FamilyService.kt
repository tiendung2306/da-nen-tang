package com.smartgrocery.service

import com.smartgrocery.dto.family.*
import com.smartgrocery.entity.*
import com.smartgrocery.exception.*
import com.smartgrocery.repository.FamilyInvitationRepository
import com.smartgrocery.repository.FamilyMemberRepository
import com.smartgrocery.repository.FamilyRepository
import com.smartgrocery.repository.FriendshipRepository
import com.smartgrocery.repository.UserRepository
import com.smartgrocery.security.CustomUserDetails
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.time.Instant
import java.util.*

@Service
class FamilyService(
    private val familyRepository: FamilyRepository,
    private val familyMemberRepository: FamilyMemberRepository,
    private val userRepository: UserRepository,
    private val familyInvitationRepository: FamilyInvitationRepository,
    private val fileStorageService: FileStorageService
) {

    @Transactional
    fun createFamily(request: CreateFamilyRequest, image: MultipartFile?): FamilyResponse {
        val currentUser = getCurrentUser()
        val user = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val inviteCode = generateInviteCode()

        // Temporarily disable image upload for debugging
        val imageUrl: String? = null // image?.let { fileStorageService.storeFile(it, "families") }

        val family = Family(
            name = request.name,
            description = request.description,
            imageUrl = imageUrl,
            inviteCode = inviteCode,
            createdBy = user
        )

        val savedFamily = familyRepository.save(family)

        // Add creator as LEADER
        val member = FamilyMember(
            id = FamilyMemberId(savedFamily.id!!, user.id!!),
            family = savedFamily,
            user = user,
            role = FamilyRole.LEADER,
            joinedAt = Instant.now()
        )
        familyMemberRepository.save(member)

        // Create invitations for friends if any are provided
        if (request.friendIds.isNotEmpty()) {
            val friends = userRepository.findAllById(request.friendIds)
            for (friend in friends) {
                // Skip if the friend doesn't exist
                if (userRepository.existsById(friend.id!!)) {
                    val invitation = FamilyInvitation(
                        family = savedFamily,
                        inviter = user,
                        invitee = friend,
                        status = InvitationStatus.PENDING
                    )
                    familyInvitationRepository.save(invitation)
                }
            }
        }

        return toFamilyResponse(savedFamily, 1) // Initially, member count is 1 (the creator)
    }

    @Transactional
    fun joinFamily(request: JoinFamilyRequest): FamilyResponse {
        val currentUser = getCurrentUser()
        val user = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val family = familyRepository.findByInviteCodeWithCreatedBy(request.inviteCode)
            ?: throw ApiException(ErrorCode.INVALID_INVITE_CODE)

        // Check if already a member
        if (familyMemberRepository.existsByFamilyIdAndUserId(family.id!!, user.id!!)) {
            throw ConflictException(ErrorCode.ALREADY_MEMBER)
        }

        val member = FamilyMember(
            id = FamilyMemberId(family.id!!, user.id!!),
            family = family,
            user = user,
            role = FamilyRole.MEMBER,
            nickname = request.nickname,
            joinedAt = Instant.now()
        )
        familyMemberRepository.save(member)

        val memberCount = familyMemberRepository.findByFamilyIdWithUsers(family.id!!).size
        return toFamilyResponse(family, memberCount)
    }

    fun getFamilyById(familyId: Long): FamilyDetailResponse {
        val currentUser = getCurrentUser()
        
        // Check membership
        if (!familyMemberRepository.existsByFamilyIdAndUserId(familyId, currentUser.id)) {
            throw ForbiddenException("You are not a member of this family")
        }

        val family = familyRepository.findByIdWithMembers(familyId)
            ?: throw ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND)

        return toFamilyDetailResponse(family)
    }

    fun getMyFamilies(): List<FamilyResponse> {
        val currentUser = getCurrentUser()
        val memberships = familyMemberRepository.findByUserIdWithFamily(currentUser.id)

        return memberships.map { membership ->
            val memberCount = familyMemberRepository.findByFamilyIdWithUsers(membership.family.id!!).size
            toFamilyResponse(membership.family, memberCount)
        }
    }

    fun getFamilyMembers(familyId: Long): List<FamilyMemberResponse> {
        val currentUser = getCurrentUser()
        
        // Check membership
        if (!familyMemberRepository.existsByFamilyIdAndUserId(familyId, currentUser.id)) {
            throw ForbiddenException("You are not a member of this family")
        }

        val members = familyMemberRepository.findByFamilyIdWithUsers(familyId)
        return members.map { toFamilyMemberResponse(it) }
    }

    @Transactional
    fun updateFamily(familyId: Long, request: UpdateFamilyRequest): FamilyResponse {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        val family = familyRepository.findById(familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        request.name?.let { family.name = it }
        request.description?.let { family.description = it }

        val savedFamily = familyRepository.save(family)
        val memberCount = familyMemberRepository.findByFamilyIdWithUsers(familyId).size

        return toFamilyResponse(savedFamily, memberCount)
    }

    @Transactional
    fun updateMember(familyId: Long, userId: Long, request: UpdateMemberRequest): FamilyMemberResponse {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        val member = familyMemberRepository.findByFamilyIdAndUserId(familyId, userId)
            ?: throw ResourceNotFoundException(ErrorCode.NOT_A_MEMBER)

        request.nickname?.let { member.nickname = it }
        request.role?.let { member.role = it }

        val savedMember = familyMemberRepository.save(member)
        return toFamilyMemberResponse(savedMember)
    }

    @Transactional
    fun removeMember(familyId: Long, userId: Long) {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        val member = familyMemberRepository.findByFamilyIdAndUserId(familyId, userId)
            ?: throw ResourceNotFoundException(ErrorCode.NOT_A_MEMBER)

        if (member.role == FamilyRole.LEADER) {
            throw ApiException(ErrorCode.CANNOT_REMOVE_LEADER)
        }

        familyMemberRepository.delete(member)
    }

    @Transactional
    fun leaveFamily(familyId: Long) {
        val currentUser = getCurrentUser()
        
        val member = familyMemberRepository.findByFamilyIdAndUserId(familyId, currentUser.id)
            ?: throw ResourceNotFoundException(ErrorCode.NOT_A_MEMBER)

        if (member.role == FamilyRole.LEADER) {
            // Check if there are other members
            val members = familyMemberRepository.findByFamilyIdWithUsers(familyId)
            if (members.size > 1) {
                throw ApiException(ErrorCode.CANNOT_REMOVE_LEADER, 
                    "Please transfer leadership before leaving the family")
            }
            // If leader is the only member, delete the family
            familyRepository.deleteById(familyId)
        } else {
            familyMemberRepository.delete(member)
        }
    }

    @Transactional
    fun regenerateInviteCode(familyId: Long): RegenerateInviteCodeResponse {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        val family = familyRepository.findById(familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        family.inviteCode = generateInviteCode()
        familyRepository.save(family)

        return RegenerateInviteCodeResponse(family.inviteCode)
    }

    @Transactional
    fun deleteFamily(familyId: Long) {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        familyRepository.deleteById(familyId)
    }

    private fun generateInviteCode(): String {
        var code: String
        do {
            code = UUID.randomUUID().toString().substring(0, 8).uppercase()
        } while (familyRepository.existsByInviteCode(code))
        return code
    }

    private fun checkLeaderPermission(familyId: Long, userId: Long) {
        val member = familyMemberRepository.findByFamilyIdAndUserId(familyId, userId)
            ?: throw ForbiddenException("You are not a member of this family")

        if (member.role != FamilyRole.LEADER) {
            throw ForbiddenException(ErrorCode.NOT_FAMILY_LEADER.message)
        }
    }

    fun isFamilyMember(familyId: Long, userId: Long): Boolean {
        return familyMemberRepository.existsByFamilyIdAndUserId(familyId, userId)
    }

    private fun getCurrentUser(): CustomUserDetails {
        val authentication = SecurityContextHolder.getContext().authentication
        return authentication.principal as CustomUserDetails
    }

    // ============================================
    // FAMILY INVITATION METHODS
    // ============================================

    fun getMyPendingInvitations(): List<FamilyInvitationResponse> {
        val currentUser = getCurrentUser()
        val invitations = familyInvitationRepository.findPendingInvitationsForUser(currentUser.id)
        return invitations.map { toFamilyInvitationResponse(it) }
    }

    @Transactional
    fun respondToInvitation(invitationId: Long, accept: Boolean): FamilyInvitationResponse {
        val currentUser = getCurrentUser()

        val invitation = familyInvitationRepository.findById(invitationId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_INVITATION_NOT_FOUND) }

        // Chỉ người được mời mới có thể phản hồi
        if (invitation.invitee.id != currentUser.id) {
            throw ForbiddenException(ErrorCode.NOT_INVITED_TO_FAMILY.message)
        }

        if (invitation.status != InvitationStatus.PENDING) {
            throw ApiException(ErrorCode.INVITATION_NOT_PENDING)
        }

        invitation.status = if (accept) InvitationStatus.ACCEPTED else InvitationStatus.REJECTED
        invitation.respondedAt = Instant.now()

        val savedInvitation = familyInvitationRepository.save(invitation)

        // Nếu chấp nhận, thêm vào family
        if (accept) {
            val user = userRepository.findById(currentUser.id)
                .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

            // Check if already a member
            if (!familyMemberRepository.existsByFamilyIdAndUserId(invitation.family.id!!, currentUser.id)) {
                val member = FamilyMember(
                    id = FamilyMemberId(invitation.family.id!!, user.id!!),
                    family = invitation.family,
                    user = user,
                    role = FamilyRole.MEMBER,
                    joinedAt = Instant.now()
                )
                familyMemberRepository.save(member)
            }
        }

        return toFamilyInvitationResponse(savedInvitation)
    }

    @Transactional
    fun inviteFriendToFamily(familyId: Long, friendId: Long): FamilyInvitationResponse {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        // Validate: phải là bạn bè
        if (!friendshipRepository.areFriends(currentUser.id, friendId)) {
            throw ApiException(ErrorCode.CAN_ONLY_INVITE_FRIENDS)
        }

        // Check if already invited or is member
        if (familyMemberRepository.existsByFamilyIdAndUserId(familyId, friendId)) {
            throw ConflictException(ErrorCode.ALREADY_MEMBER)
        }

        val existingInvitation = familyInvitationRepository.findByFamilyIdAndInviteeId(familyId, friendId)
        if (existingInvitation != null && existingInvitation.status == InvitationStatus.PENDING) {
            throw ConflictException(ErrorCode.FAMILY_INVITATION_NOT_FOUND, "Invitation already sent")
        }

        val user = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val friend = userRepository.findById(friendId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val family = familyRepository.findById(familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        val invitation = FamilyInvitation(
            family = family,
            inviter = user,
            invitee = friend,
            status = InvitationStatus.PENDING
        )

        val savedInvitation = familyInvitationRepository.save(invitation)
        return toFamilyInvitationResponse(savedInvitation)
    }

    // ============================================
    // UPDATE FAMILY WITH IMAGE
    // ============================================

    @Transactional
    fun updateFamilyWithImage(familyId: Long, request: UpdateFamilyRequest, image: MultipartFile?): FamilyResponse {
        val currentUser = getCurrentUser()
        checkLeaderPermission(familyId, currentUser.id)

        val family = familyRepository.findById(familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        request.name?.let { family.name = it }
        request.description?.let { family.description = it }

        // Update image if provided
        image?.let {
            // Delete old image if exists
            family.imageUrl?.let { oldUrl ->
                fileStorageService.deleteFile(oldUrl)
            }
            family.imageUrl = fileStorageService.storeFile(it, "families")
        }

        val savedFamily = familyRepository.save(family)
        val memberCount = familyMemberRepository.findByFamilyIdWithUsers(familyId).size

        return toFamilyResponse(savedFamily, memberCount)
    }

    // ============================================
    // RESPONSE MAPPING METHODS
    // ============================================

    private fun toFamilyResponse(family: Family, memberCount: Int): FamilyResponse {
        return FamilyResponse(
            id = family.id!!,
            name = family.name,
            description = family.description,
            imageUrl = family.imageUrl?.let { "/files/$it" },
            inviteCode = family.inviteCode,
            createdBy = UserSimpleResponse(
                id = family.createdBy.id!!,
                username = family.createdBy.username,
                fullName = family.createdBy.fullName
            ),
            memberCount = memberCount,
            createdAt = family.createdAt
        )
    }

    private fun toFamilyDetailResponse(family: Family): FamilyDetailResponse {
        val invitations = familyInvitationRepository.findByFamilyIdWithDetails(family.id!!)
            .filter { it.status == InvitationStatus.PENDING }

        return FamilyDetailResponse(
            id = family.id!!,
            name = family.name,
            description = family.description,
            imageUrl = family.imageUrl?.let { "/files/$it" },
            inviteCode = family.inviteCode,
            createdBy = UserSimpleResponse(
                id = family.createdBy.id!!,
                username = family.createdBy.username,
                fullName = family.createdBy.fullName
            ),
            members = family.members.map { toFamilyMemberResponse(it) },
            pendingInvitations = invitations.map { toFamilyInvitationResponse(it) },
            createdAt = family.createdAt
        )
    }

    private fun toFamilyMemberResponse(member: FamilyMember): FamilyMemberResponse {
        return FamilyMemberResponse(
            userId = member.user.id!!,
            username = member.user.username,
            fullName = member.user.fullName,
            email = member.user.email,
            role = member.role,
            nickname = member.nickname,
            joinedAt = member.joinedAt
        )
    }

    private fun toFamilyInvitationResponse(invitation: FamilyInvitation): FamilyInvitationResponse {
        return FamilyInvitationResponse(
            id = invitation.id!!,
            familyId = invitation.family.id!!,
            familyName = invitation.family.name,
            inviter = UserSimpleResponse(
                id = invitation.inviter.id!!,
                username = invitation.inviter.username,
                fullName = invitation.inviter.fullName
            ),
            invitee = UserSimpleResponse(
                id = invitation.invitee.id!!,
                username = invitation.invitee.username,
                fullName = invitation.invitee.fullName
            ),
            status = invitation.status,
            createdAt = invitation.createdAt
        )
    }
}
