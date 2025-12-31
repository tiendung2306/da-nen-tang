package com.smartgrocery.service

import com.smartgrocery.dto.friendship.*
import com.smartgrocery.entity.Friendship
import com.smartgrocery.entity.FriendshipStatus
import com.smartgrocery.exception.*
import com.smartgrocery.repository.FriendshipRepository
import com.smartgrocery.repository.UserRepository
import com.smartgrocery.security.CustomUserDetails
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class FriendshipService(
    private val friendshipRepository: FriendshipRepository,
    private val userRepository: UserRepository
) {

    @Transactional
    fun sendFriendRequest(request: SendFriendRequestDto): FriendRequestResponse {
        val currentUser = getCurrentUser()

        if (request.userId == currentUser.id) {
            throw ApiException(ErrorCode.CANNOT_SEND_REQUEST_TO_SELF)
        }

        val addressee = userRepository.findById(request.userId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val requester = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val existingFriendship = friendshipRepository.findByUserPair(currentUser.id, request.userId)
        if (existingFriendship != null) {
            when (existingFriendship.status) {
                FriendshipStatus.ACCEPTED -> throw ApiException(ErrorCode.ALREADY_FRIENDS)
                FriendshipStatus.PENDING -> throw ApiException(ErrorCode.FRIEND_REQUEST_ALREADY_EXISTS)
                FriendshipStatus.REJECTED -> {
                    existingFriendship.status = FriendshipStatus.PENDING
                    existingFriendship.requester = requester
                    existingFriendship.addressee = addressee
                    val saved = friendshipRepository.save(existingFriendship)
                    return toFriendRequestResponse(saved)
                }
                FriendshipStatus.BLOCKED -> throw ForbiddenException("Cannot send friend request")
            }
        }

        val friendship = Friendship(
            requester = requester,
            addressee = addressee,
            status = FriendshipStatus.PENDING
        )

        val savedFriendship = friendshipRepository.save(friendship)
        return toFriendRequestResponse(savedFriendship)
    }

    @Transactional
    fun respondToFriendRequest(friendshipId: Long, accept: Boolean): Any {
        val currentUser = getCurrentUser()

        val friendship = friendshipRepository.findByIdWithUsers(friendshipId)
            ?: throw ResourceNotFoundException(ErrorCode.FRIENDSHIP_NOT_FOUND)

        if (friendship.addressee.id != currentUser.id) {
            throw ForbiddenException(ErrorCode.NOT_YOUR_FRIEND_REQUEST.message)
        }

        if (friendship.status != FriendshipStatus.PENDING) {
            throw ApiException(ErrorCode.FRIEND_REQUEST_NOT_PENDING)
        }

        friendship.status = if (accept) FriendshipStatus.ACCEPTED else FriendshipStatus.REJECTED
        val savedFriendship = friendshipRepository.save(friendship)

        return if (accept) {
            val newFriend = savedFriendship.requester
            val friendResponse = FriendResponse(
                id = newFriend.id!!,
                username = newFriend.username,
                fullName = newFriend.fullName,
                email = newFriend.email,
                friendshipId = savedFriendship.id!!,
                friendsSince = savedFriendship.updatedAt
            )
            val requestResponse = toFriendRequestResponse(savedFriendship)
            AcceptFriendRequestResponse(friendship = friendResponse, request = requestResponse)
        } else {
            toFriendRequestResponse(savedFriendship)
        }
    }

    fun getFriends(): List<FriendResponse> {
        val currentUser = getCurrentUser()
        val friendships = friendshipRepository.findByUserIdAndStatusWithUsers(
            currentUser.id,
            FriendshipStatus.ACCEPTED
        )

        return friendships.map { friendship ->
            val friend = if (friendship.requester.id == currentUser.id) {
                friendship.addressee
            } else {
                friendship.requester
            }

            FriendResponse(
                id = friend.id!!,
                username = friend.username,
                fullName = friend.fullName,
                email = friend.email,
                friendshipId = friendship.id!!,
                friendsSince = friendship.updatedAt
            )
        }
    }

    fun getPendingRequests(): List<FriendRequestResponse> {
        val currentUser = getCurrentUser()
        val requests = friendshipRepository.findPendingRequestsForUser(currentUser.id)
        return requests.map { toFriendRequestResponse(it) }
    }

    fun getSentRequests(): List<FriendRequestResponse> {
        val currentUser = getCurrentUser()
        val requests = friendshipRepository.findSentRequestsByUser(currentUser.id)
        return requests.map { toFriendRequestResponse(it) }
    }

    fun getFriendshipStatus(userId: Long): FriendshipStatusResponse {
        val currentUser = getCurrentUser()

        if (userId == currentUser.id) {
            return FriendshipStatusResponse(
                areFriends = false,
                status = null,
                friendshipId = null
            )
        }

        val friendship = friendshipRepository.findByUserPair(currentUser.id, userId)

        return FriendshipStatusResponse(
            areFriends = friendship?.status == FriendshipStatus.ACCEPTED,
            status = friendship?.status,
            friendshipId = friendship?.id
        )
    }

    @Transactional
    fun unfriend(userId: Long) {
        val currentUser = getCurrentUser()

        val friendship = friendshipRepository.findByUserPair(currentUser.id, userId)
            ?: throw ResourceNotFoundException(ErrorCode.FRIENDSHIP_NOT_FOUND)

        if (friendship.status != FriendshipStatus.ACCEPTED) {
            throw ApiException(ErrorCode.NOT_FRIENDS)
        }

        friendshipRepository.delete(friendship)
    }

    @Transactional
    fun cancelFriendRequest(friendshipId: Long) {
        val currentUser = getCurrentUser()

        val friendship = friendshipRepository.findByIdWithUsers(friendshipId)
            ?: throw ResourceNotFoundException(ErrorCode.FRIENDSHIP_NOT_FOUND)

        if (friendship.requester.id != currentUser.id) {
            throw ForbiddenException("You can only cancel your own friend requests")
        }

        if (friendship.status != FriendshipStatus.PENDING) {
            throw ApiException(ErrorCode.FRIEND_REQUEST_NOT_PENDING)
        }

        friendshipRepository.delete(friendship)
    }

    fun areFriends(userId1: Long, userId2: Long): Boolean {
        return friendshipRepository.areFriends(userId1, userId2)
    }

    private fun getCurrentUser(): CustomUserDetails {
        val authentication = SecurityContextHolder.getContext().authentication
        return authentication.principal as CustomUserDetails
    }

    private fun toFriendRequestResponse(friendship: Friendship): FriendRequestResponse {
        return FriendRequestResponse(
            id = friendship.id!!,
            requester = UserBasicInfo(
                id = friendship.requester.id!!,
                username = friendship.requester.username,
                fullName = friendship.requester.fullName,
                email = friendship.requester.email
            ),
            addressee = UserBasicInfo(
                id = friendship.addressee.id!!,
                username = friendship.addressee.username,
                fullName = friendship.addressee.fullName,
                email = friendship.addressee.email
            ),
            status = friendship.status,
            createdAt = friendship.createdAt
        )
    }
}
