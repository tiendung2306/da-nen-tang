package com.smartgrocery.scheduler

import com.smartgrocery.dto.fridge.ExpiringItemNotification
import com.smartgrocery.repository.FamilyMemberRepository
import com.smartgrocery.repository.FridgeItemRepository
import com.smartgrocery.repository.UserRepository
import com.smartgrocery.service.NotificationManagementService
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@Component
class ExpirationNotificationScheduler(
    private val fridgeItemRepository: FridgeItemRepository,
    private val familyMemberRepository: FamilyMemberRepository,
    private val userRepository: UserRepository,
    private val notificationService: NotificationService,
    private val notificationManagementService: NotificationManagementService
) {

    private val logger = LoggerFactory.getLogger(ExpirationNotificationScheduler::class.java)

    /**
     * Runs every day at 8:00 AM to check for expiring items (3 days threshold)
     */
    @Scheduled(cron = "0 0 8 * * *")
    fun checkExpiringItems() {
        logger.info("Starting daily expiration check (3-day threshold)...")
        processExpiringItems(daysThreshold = 3)
    }

    /**
     * Runs every day at 9:00 AM to check for critical items (24 hours threshold)
     */
    @Scheduled(cron = "0 0 9 * * *")
    fun checkCriticalExpiringItems() {
        logger.info("Starting critical expiration check (24-hour threshold)...")
        processExpiringItems(daysThreshold = 1)
    }

    /**
     * Runs every day at 10:00 AM to check for already expired items
     */
    @Scheduled(cron = "0 0 10 * * *")
    fun checkExpiredItems() {
        logger.info("Starting expired items check...")
        
        val today = LocalDate.now()
        val expiredItems = fridgeItemRepository.findExpiredWithDetails(today)

        if (expiredItems.isEmpty()) {
            logger.info("No expired items found")
            return
        }

        logger.info("Found ${expiredItems.size} expired items")

        // Group by family
        val itemsByFamily = expiredItems.groupBy { it.family.id!! }

        var totalNotificationsCreated = 0

        itemsByFamily.forEach { (familyId, items) ->
            val family = items.first().family
            val familyName = family.name

            // Get all family members
            val members = familyMemberRepository.findByFamilyIdWithUsers(familyId)

            items.forEach { item ->
                members.forEach { member ->
                    val notification = notificationManagementService.createExpiryNotification(
                        user = member.user,
                        itemId = item.id!!,
                        productName = item.getProductName(),
                        daysUntilExpiry = 0, // Already expired
                        familyName = familyName
                    )
                    if (notification != null) totalNotificationsCreated++
                }
            }

            // Send push notification to family
            val notifications = items.map { item ->
                ExpiringItemNotification(
                    itemId = item.id!!,
                    productName = item.getProductName(),
                    expirationDate = item.expirationDate!!,
                    daysUntilExpiration = 0,
                    familyId = familyId,
                    familyName = familyName
                )
            }
            notificationService.sendExpiringItemsNotification(familyId, notifications)

            // Update status to EXPIRED
            items.forEach { item ->
                item.status = com.smartgrocery.entity.FridgeItemStatus.EXPIRED
            }
            fridgeItemRepository.saveAll(items)
        }

        logger.info("Expired items check completed. Created $totalNotificationsCreated notifications")
    }

    /**
     * Process expiring items for a given days threshold
     */
    private fun processExpiringItems(daysThreshold: Int) {
        val today = LocalDate.now()
        val thresholdDate = today.plusDays(daysThreshold.toLong())

        // Find items expiring within threshold
        val expiringItems = fridgeItemRepository.findExpiringSoonWithDetails(today, thresholdDate)

        if (expiringItems.isEmpty()) {
            logger.info("No items expiring within the next $daysThreshold days")
            return
        }

        logger.info("Found ${expiringItems.size} items expiring within $daysThreshold days")

        // Group by family
        val itemsByFamily = expiringItems.groupBy { it.family.id!! }
        
        var totalNotificationsCreated = 0

        itemsByFamily.forEach { (familyId, items) ->
            val family = items.first().family
            val familyName = family.name
            
            // Get all family members
            val members = familyMemberRepository.findByFamilyIdWithUsers(familyId)

            // Create database notification for each member for each item
            items.forEach { item ->
                val daysUntilExpiry = ChronoUnit.DAYS.between(today, item.expirationDate)
                
                members.forEach { member ->
                    val notification = notificationManagementService.createExpiryNotification(
                        user = member.user,
                        itemId = item.id!!,
                        productName = item.getProductName(),
                        daysUntilExpiry = daysUntilExpiry,
                        familyName = familyName
                    )
                    if (notification != null) totalNotificationsCreated++
                }
            }

            // Prepare push notification data
            val pushNotifications = items.map { item ->
                val daysUntilExpiration = ChronoUnit.DAYS.between(today, item.expirationDate)
                
                ExpiringItemNotification(
                    itemId = item.id!!,
                    productName = item.getProductName(),
                    expirationDate = item.expirationDate!!,
                    daysUntilExpiration = daysUntilExpiration,
                    familyId = familyId,
                    familyName = familyName
                )
            }

            // Send push notification to family members
            notificationService.sendExpiringItemsNotification(familyId, pushNotifications)
        }

        logger.info("Expiration check completed. Created $totalNotificationsCreated database notifications")
    }

    /**
     * Runs every hour to check for newly expired items and update status
     */
    @Scheduled(cron = "0 0 * * * *")
    fun updateExpiredItemsStatus() {
        val today = LocalDate.now()
        val expiredItems = fridgeItemRepository.findExpiredWithDetails(today)

        if (expiredItems.isNotEmpty()) {
            logger.info("Updating ${expiredItems.size} expired items status")
            expiredItems.forEach { item ->
                item.status = com.smartgrocery.entity.FridgeItemStatus.EXPIRED
            }
            fridgeItemRepository.saveAll(expiredItems)
        }
    }

    /**
     * Runs every week at Sunday midnight to cleanup old notifications
     */
    @Scheduled(cron = "0 0 0 * * SUN")
    fun cleanupOldNotifications() {
        logger.info("Starting weekly notification cleanup...")
        val deleted = notificationManagementService.cleanupOldNotifications()
        logger.info("Notification cleanup completed. Deleted $deleted old notifications")
    }
}

