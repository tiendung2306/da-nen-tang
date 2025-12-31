package com.smartgrocery.controller

import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.family.*
import com.smartgrocery.service.FamilyService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping("/api/v1/families")
@Tag(name = "Families", description = "Family management APIs")
class FamilyController(
    private val familyService: FamilyService
) {

    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    @Operation(summary = "Create a new family with image and invite friends")
    fun createFamily(
        @RequestParam("name") name: String,
        @RequestParam("description", required = false) description: String?,
        @RequestParam("friendIds", required = false) friendIds: List<Long>?,
        @Parameter(description = "Family image")
        @RequestPart("image", required = false) image: MultipartFile?
    ): ResponseEntity<ApiResponse<FamilyResponse>> {
        val request = CreateFamilyRequest(
            name = name,
            description = description,
            friendIds = friendIds ?: emptyList()
        )
        val family = familyService.createFamily(request, image)
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.created(family, "Family created successfully"))
    }

    @PostMapping("/join")
    @Operation(summary = "Join a family using invite code")
    fun joinFamily(
        @Valid @RequestBody request: JoinFamilyRequest
    ): ResponseEntity<ApiResponse<FamilyResponse>> {
        val family = familyService.joinFamily(request)
        return ResponseEntity.ok(ApiResponse.success(family, "Joined family successfully"))
    }

    @GetMapping
    @Operation(summary = "Get all families the current user belongs to")
    fun getMyFamilies(): ResponseEntity<ApiResponse<List<FamilyResponse>>> {
        val families = familyService.getMyFamilies()
        return ResponseEntity.ok(ApiResponse.success(families))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get family details by ID")
    fun getFamilyById(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<FamilyDetailResponse>> {
        val family = familyService.getFamilyById(id)
        return ResponseEntity.ok(ApiResponse.success(family))
    }

    @GetMapping("/{id}/members")
    @Operation(summary = "Get all members of a family")
    fun getFamilyMembers(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<List<FamilyMemberResponse>>> {
        val members = familyService.getFamilyMembers(id)
        return ResponseEntity.ok(ApiResponse.success(members))
    }

    @PutMapping("/{id}", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    @Operation(summary = "Update family information with optional image (Leader only)")
    fun updateFamily(
        @PathVariable id: Long,
        @RequestParam("name", required = false) name: String?,
        @RequestParam("description", required = false) description: String?,
        @Parameter(description = "Family image")
        @RequestPart("image", required = false) image: MultipartFile?
    ): ResponseEntity<ApiResponse<FamilyResponse>> {
        val request = UpdateFamilyRequest(name = name, description = description)
        val family = familyService.updateFamilyWithImage(id, request, image)
        return ResponseEntity.ok(ApiResponse.success(family, "Family updated successfully"))
    }

    @PatchMapping("/{familyId}/members/{userId}")
    @Operation(summary = "Update a family member (Leader only)")
    fun updateMember(
        @PathVariable familyId: Long,
        @PathVariable userId: Long,
        @Valid @RequestBody request: UpdateMemberRequest
    ): ResponseEntity<ApiResponse<FamilyMemberResponse>> {
        val member = familyService.updateMember(familyId, userId, request)
        return ResponseEntity.ok(ApiResponse.success(member, "Member updated successfully"))
    }

    @DeleteMapping("/{familyId}/members/{userId}")
    @Operation(summary = "Remove a member from family (Leader only)")
    fun removeMember(
        @PathVariable familyId: Long,
        @PathVariable userId: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        familyService.removeMember(familyId, userId)
        return ResponseEntity.ok(ApiResponse.success("Member removed successfully"))
    }

    @PostMapping("/{id}/leave")
    @Operation(summary = "Leave a family")
    fun leaveFamily(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        familyService.leaveFamily(id)
        return ResponseEntity.ok(ApiResponse.success("Left family successfully"))
    }

    @PostMapping("/{id}/regenerate-invite-code")
    @Operation(summary = "Regenerate family invite code (Leader only)")
    fun regenerateInviteCode(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<RegenerateInviteCodeResponse>> {
        val response = familyService.regenerateInviteCode(id)
        return ResponseEntity.ok(ApiResponse.success(response, "Invite code regenerated"))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a family (Leader only)")
    fun deleteFamily(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        familyService.deleteFamily(id)
        return ResponseEntity.ok(ApiResponse.success("Family deleted successfully"))
    }

    // ============================================
    // FAMILY INVITATION ENDPOINTS
    // ============================================

    @GetMapping("/invitations")
    @Operation(summary = "Get my pending family invitations")
    fun getMyPendingInvitations(): ResponseEntity<ApiResponse<List<FamilyInvitationResponse>>> {
        val invitations = familyService.getMyPendingInvitations()
        return ResponseEntity.ok(ApiResponse.success(invitations))
    }

    @PostMapping("/invitations/{invitationId}/respond")
    @Operation(summary = "Accept or reject a family invitation")
    fun respondToInvitation(
        @PathVariable invitationId: Long,
        @Valid @RequestBody request: RespondToInvitationRequest
    ): ResponseEntity<ApiResponse<FamilyInvitationResponse>> {
        val result = familyService.respondToInvitation(invitationId, request.accept)
        val message = if (request.accept) "Invitation accepted" else "Invitation rejected"
        return ResponseEntity.ok(ApiResponse.success(result, message))
    }

    @PostMapping("/{familyId}/invite/{friendId}")
    @Operation(summary = "Invite a friend to join family (Leader only)")
    fun inviteFriendToFamily(
        @PathVariable familyId: Long,
        @PathVariable friendId: Long
    ): ResponseEntity<ApiResponse<FamilyInvitationResponse>> {
        val invitation = familyService.inviteFriendToFamily(familyId, friendId)
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.created(invitation, "Invitation sent"))
    }
}
