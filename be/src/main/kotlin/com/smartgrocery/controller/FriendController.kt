package com.smartgrocery.controller

import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.friendship.*
import com.smartgrocery.service.FriendshipService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/friends")
@Tag(name = "Friends", description = "Friend management APIs")
class FriendController(
    private val friendshipService: FriendshipService
) {

    @PostMapping("/requests")
    @Operation(summary = "Send a friend request")
    fun sendFriendRequest(
        @Valid @RequestBody request: SendFriendRequestDto
    ): ResponseEntity<ApiResponse<FriendRequestResponse>> {
        val friendRequest = friendshipService.sendFriendRequest(request)
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.created(friendRequest, "Friend request sent"))
    }

    @PostMapping("/requests/{id}/respond")
    @Operation(summary = "Accept or reject a friend request")
    fun respondToFriendRequest(
        @PathVariable id: Long,
        @Valid @RequestBody request: RespondFriendRequestDto
    ): ResponseEntity<ApiResponse<Any>> {
        val result = friendshipService.respondToFriendRequest(id, request.accept)
        val message = if (request.accept) "Friend request accepted" else "Friend request rejected"
        return ResponseEntity.ok(ApiResponse.success(result, message))
    }

    @DeleteMapping("/requests/{id}")
    @Operation(summary = "Cancel a sent friend request")
    fun cancelFriendRequest(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        friendshipService.cancelFriendRequest(id)
        return ResponseEntity.ok(ApiResponse.success("Friend request cancelled"))
    }

    @GetMapping
    @Operation(summary = "Get all friends")
    fun getFriends(): ResponseEntity<ApiResponse<List<FriendResponse>>> {
        val friends = friendshipService.getFriends()
        return ResponseEntity.ok(ApiResponse.success(friends))
    }

    @GetMapping("/requests/received")
    @Operation(summary = "Get pending friend requests received")
    fun getPendingRequests(): ResponseEntity<ApiResponse<List<FriendRequestResponse>>> {
        val requests = friendshipService.getPendingRequests()
        return ResponseEntity.ok(ApiResponse.success(requests))
    }

    @GetMapping("/requests/sent")
    @Operation(summary = "Get friend requests sent by current user")
    fun getSentRequests(): ResponseEntity<ApiResponse<List<FriendRequestResponse>>> {
        val requests = friendshipService.getSentRequests()
        return ResponseEntity.ok(ApiResponse.success(requests))
    }

    @GetMapping("/status/{userId}")
    @Operation(summary = "Get friendship status with a user")
    fun getFriendshipStatus(
        @PathVariable userId: Long
    ): ResponseEntity<ApiResponse<FriendshipStatusResponse>> {
        val status = friendshipService.getFriendshipStatus(userId)
        return ResponseEntity.ok(ApiResponse.success(status))
    }

    @DeleteMapping("/{userId}")
    @Operation(summary = "Unfriend a user")
    fun unfriend(
        @PathVariable userId: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        friendshipService.unfriend(userId)
        return ResponseEntity.ok(ApiResponse.success("Unfriended successfully"))
    }
}
