package com.smartgrocery.dto.friendship

import com.smartgrocery.entity.FriendshipStatus
import jakarta.validation.constraints.NotNull
import java.time.Instant

// ============================================
// REQUEST DTOs
// ============================================

data class SendFriendRequestDto(
    @field:NotNull(message = "User ID is required")
    val userId: Long
)

data class RespondFriendRequestDto(
    val accept: Boolean
)

// ============================================
// RESPONSE DTOs
// ============================================

data class FriendResponse(
    val id: Long,
    val username: String,
    val fullName: String,
    val email: String,
    val friendshipId: Long,
    val friendsSince: Instant
)

data class FriendRequestResponse(
    val id: Long,
    val requester: UserBasicInfo,
    val addressee: UserBasicInfo,
    val status: FriendshipStatus,
    val createdAt: Instant
)

data class UserBasicInfo(
    val id: Long,
    val username: String,
    val fullName: String,
    val email: String
)

data class FriendshipStatusResponse(
    val areFriends: Boolean,
    val status: FriendshipStatus?,
    val friendshipId: Long?
)

// New DTO for the response of accepting a friend request
data class AcceptFriendRequestResponse(
    val friendship: FriendResponse,
    val request: FriendRequestResponse
)
