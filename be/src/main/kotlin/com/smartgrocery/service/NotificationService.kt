package com.smartgrocery.service

import com.smartgrocery.dto.notification.*
import com.smartgrocery.entity.Notification
import com.smartgrocery.entity.NotificationType
import com.smartgrocery.entity.User
import com.smartgrocery.exception.ErrorCode
import com.smartgrocery.exception.ResourceNotFoundException
import com.smartgrocery.repository.NotificationRepository
import com.smartgrocery.repository.UserRepository
import com.smartgrocery.security.CustomUserDetails
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Pageable
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.temporal.ChronoUnit

@Service
class NotificationManagementService(
    private val notificationRepository: NotificationRepository,
    private val userRepository: UserRepository
) {
    private val logger = LoggerFactory.getLogger(NotificationManagementService::class.java)

    private fun getCurrentUser(): CustomUserDetails {
        return SecurityContextHolder.getContext().authentication.principal as CustomUserDetails
    }

    @Transactional(readOnly = true)
    fun getNotifications(unreadOnly: Boolean?, pageable: Pageable): PaginatedNotifications {
        val currentUser = getCurrentUser()
        
        val page = if (unreadOnly == true) {
            notificationRepository.findByUserIdAndIsRead(currentUser.id, false, pageable)
        } else {
            notificationRepository.findByUserId(currentUser.id, pageable)
        }

        return PaginatedNotifications(
            content = page.content.map { toResponse(it) },
            totalElements = page.totalElements,
            totalPages = page.totalPages,
            number = page.number,
            size = page.size,
            first = page.isFirst,
            last = page.isLast
        )
    }

    @Transactional(readOnly = true)
    fun getNotificationCount(): NotificationCountResponse {
        val currentUser = getCurrentUser()
        
        return NotificationCountResponse(
            total = notificationRepository.countByUserId(currentUser.id),
            unread = notificationRepository.countByUserIdAndIsRead(currentUser.id, false)
        )
    }

    @Transactional
    fun markAsRead(ids: List<Long>) {
        val currentUser = getCurrentUser()
        notificationRepository.markAsReadByIds(ids, currentUser.id)
    }

    @Transactional
    fun markAllAsRead() {
        val currentUser = getCurrentUser()
        notificationRepository.markAllAsRead(currentUser.id)
    }

    @Transactional
    fun deleteNotification(id: Long) {
        val currentUser = getCurrentUser()
        val deleted = notificationRepository.deleteByIdAndUserId(id, currentUser.id)
        if (deleted == 0) {
            throw ResourceNotFoundException(ErrorCode.NOTIFICATION_NOT_FOUND)
        }
    }

    /**
     * Create a notification for a user (used by scheduled jobs)
     * Returns null if duplicate notification exists within the deduplication window
     */
    @Transactional
    fun createNotification(
        user: User,
        title: String,
        message: String,
        type: NotificationType,
        referenceType: String? = null,
        referenceId: Long? = null,
        deduplicationHours: Long = 24 // Don't create duplicate within this timeframe
    ): Notification? {
        // Check for duplicate notification
        if (referenceType != null && referenceId != null) {
            val since = Instant.now().minus(deduplicationHours, ChronoUnit.HOURS)
            val exists = notificationRepository.existsByUserAndReference(
                userId = user.id!!,
                type = type,
                referenceType = referenceType,
                referenceId = referenceId,
                since = since
            )
            if (exists) {
                logger.debug("Skipping duplicate notification for user ${user.id}, type=$type, refId=$referenceId")
                return null
            }
        }

        val notification = Notification(
            user = user,
            title = title,
            message = message,
            type = type,
            referenceType = referenceType,
            referenceId = referenceId
        )

        val saved = notificationRepository.save(notification)
        logger.info("Created notification ${saved.id} for user ${user.id}: $title")
        return saved
    }

    /**
     * Create expiry notification for fridge item
     */
    @Transactional
    fun createExpiryNotification(
        user: User,
        itemId: Long,
        productName: String,
        daysUntilExpiry: Long,
        familyName: String
    ): Notification? {
        val (title, message) = when {
            daysUntilExpiry <= 0 -> {
                "🔴 $productName đã hết hạn!" to 
                "$productName trong tủ lạnh của gia đình $familyName đã hết hạn sử dụng. Hãy kiểm tra và xử lý ngay!"
            }
            daysUntilExpiry == 1L -> {
                "🟠 $productName sắp hết hạn!" to 
                "$productName trong tủ lạnh của gia đình $familyName sẽ hết hạn vào ngày mai. Hãy sử dụng sớm!"
            }
            else -> {
                "🟡 $productName sắp hết hạn" to 
                "$productName trong tủ lạnh của gia đình $familyName sẽ hết hạn trong $daysUntilExpiry ngày."
            }
        }

        return createNotification(
            user = user,
            title = title,
            message = message,
            type = NotificationType.FRIDGE_EXPIRY,
            referenceType = "FRIDGE_ITEM",
            referenceId = itemId,
            deduplicationHours = if (daysUntilExpiry <= 1) 12 else 24 // More frequent for urgent items
        )
    }

    /**
     * Cleanup old read notifications (older than 30 days)
     */
    @Transactional
    fun cleanupOldNotifications(): Int {
        val before = Instant.now().minus(30, ChronoUnit.DAYS)
        val deleted = notificationRepository.deleteOldReadNotifications(before)
        if (deleted > 0) {
            logger.info("Cleaned up $deleted old read notifications")
        }
        return deleted
    }

    private fun toResponse(notification: Notification): NotificationResponse {
        return NotificationResponse(
            id = notification.id!!,
            title = notification.title,
            message = notification.message,
            type = notification.type,
            referenceType = notification.referenceType,
            referenceId = notification.referenceId,
            isRead = notification.isRead,
            createdAt = notification.createdAt,
            readAt = notification.readAt
        )
    }
}
