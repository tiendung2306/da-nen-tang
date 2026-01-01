package com.smartgrocery.entity

import jakarta.persistence.*
import java.time.Instant

enum class NotificationType {
    GENERAL,
    FAMILY_INVITE,
    FRIEND_REQUEST,
    FRIDGE_EXPIRY,
    SHOPPING_REMINDER,
    MEAL_PLAN
}

@Entity
@Table(name = "notifications")
class Notification(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    var user: User,

    @Column(name = "title", length = 200, nullable = false)
    var title: String,

    @Column(name = "message", columnDefinition = "TEXT", nullable = false)
    var message: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 50, nullable = false)
    var type: NotificationType = NotificationType.GENERAL,

    @Column(name = "reference_type", length = 50)
    var referenceType: String? = null,

    @Column(name = "reference_id")
    var referenceId: Long? = null,

    @Column(name = "is_read", nullable = false)
    var isRead: Boolean = false,

    @Column(name = "read_at")
    var readAt: Instant? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now()
) {
    @PreUpdate
    fun preUpdate() {
        updatedAt = Instant.now()
    }
}
