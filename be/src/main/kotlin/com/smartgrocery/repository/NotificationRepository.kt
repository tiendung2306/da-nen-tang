package com.smartgrocery.repository

import com.smartgrocery.entity.Notification
import com.smartgrocery.entity.NotificationType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.Instant

@Repository
interface NotificationRepository : JpaRepository<Notification, Long> {
    
    fun findByUserId(userId: Long, pageable: Pageable): Page<Notification>
    
    fun findByUserIdAndIsRead(userId: Long, isRead: Boolean, pageable: Pageable): Page<Notification>
    
    fun countByUserIdAndIsRead(userId: Long, isRead: Boolean): Int
    
    fun countByUserId(userId: Long): Int
    
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.id IN :ids AND n.user.id = :userId")
    fun markAsReadByIds(ids: List<Long>, userId: Long): Int
    
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.user.id = :userId AND n.isRead = false")
    fun markAllAsRead(userId: Long): Int
    
    fun deleteByIdAndUserId(id: Long, userId: Long): Int
    
    /**
     * Check if notification already exists for this user, type, and reference within time range
     * Used to prevent duplicate notifications for same fridge item
     */
    @Query("""
        SELECT COUNT(n) > 0 FROM Notification n 
        WHERE n.user.id = :userId 
        AND n.type = :type 
        AND n.referenceType = :referenceType 
        AND n.referenceId = :referenceId 
        AND n.createdAt >= :since
    """)
    fun existsByUserAndReference(
        userId: Long, 
        type: NotificationType, 
        referenceType: String, 
        referenceId: Long, 
        since: Instant
    ): Boolean
    
    /**
     * Delete old read notifications (cleanup job)
     */
    @Modifying
    @Query("DELETE FROM Notification n WHERE n.isRead = true AND n.createdAt < :before")
    fun deleteOldReadNotifications(before: Instant): Int
}
