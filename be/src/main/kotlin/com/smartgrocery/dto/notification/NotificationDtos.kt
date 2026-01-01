package com.smartgrocery.dto.notification

import com.smartgrocery.entity.NotificationType
import java.time.Instant

data class NotificationResponse(
    val id: Long,
    val title: String,
    val message: String,
    val type: NotificationType,
    val referenceType: String?,
    val referenceId: Long?,
    val isRead: Boolean,
    val createdAt: Instant,
    val readAt: Instant?
)

data class NotificationCountResponse(
    val total: Int,
    val unread: Int
)

data class PaginatedNotifications(
    val content: List<NotificationResponse>,
    val totalElements: Long,
    val totalPages: Int,
    val number: Int,
    val size: Int,
    val first: Boolean,
    val last: Boolean
)

data class MarkAsReadRequest(
    val notificationIds: List<Long>
)
