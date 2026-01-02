package com.smartgrocery.scheduler

import com.smartgrocery.dto.fridge.ExpiringItemNotification
import com.smartgrocery.repository.FridgeItemRepository
import com.smartgrocery.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@Component
class ExpirationNotificationScheduler(
    private val fridgeItemRepository: FridgeItemRepository,
    private val userRepository: UserRepository,
    private val notificationService: NotificationService
) {

    private val logger = LoggerFactory.getLogger(ExpirationNotificationScheduler::class.java)

    /**
     * Runs every day at 8:00 AM to check for expiring items
     */
    @Scheduled(cron = "0 0 8 * * *")
    fun checkExpiringItems() {
        logger.info("Starting daily expiration check...")

        val today = LocalDate.now()
        val thresholdDate = today.plusDays(3)

        // Find items expiring within 3 days
        val expiringItems = fridgeItemRepository.findExpiringSoonWithDetails(today, thresholdDate)

        if (expiringItems.isEmpty()) {
            logger.info("No items expiring within the next 3 days")
            return
        }

        logger.info("Found ${expiringItems.size} items expiring soon")

        // Group by family
        val itemsByFamily = expiringItems.groupBy { it.family.id!! }

        itemsByFamily.forEach { (familyId, items) ->
            val family = items.first().family
            
            val notifications = items.map { item ->
                val daysUntilExpiration = ChronoUnit.DAYS.between(today, item.expirationDate)
                
                ExpiringItemNotification(
                    itemId = item.id!!,
                    productName = item.getProductName(),
                    expirationDate = item.expirationDate!!,
                    daysUntilExpiration = daysUntilExpiration,
                    familyId = familyId,
                    familyName = family.name
                )
            }

            // Send notification to family members
            notificationService.sendExpiringItemsNotification(familyId, notifications)
        }

        // Check and update expired items status
        val expiredItems = fridgeItemRepository.findExpiredWithDetails(today)
        if (expiredItems.isNotEmpty()) {
            logger.info("Found ${expiredItems.size} expired items to update")
            
            // Group expired items by family
            val expiredByFamily = expiredItems.groupBy { it.family.id!! }
            
            expiredByFamily.forEach { (familyId, items) ->
                val family = items.first().family
                
                items.forEach { item ->
                    val notification = ExpiringItemNotification(
                        itemId = item.id!!,
                        productName = item.getProductName(),
                        expirationDate = item.expirationDate!!,
                        daysUntilExpiration = 0L,
                        familyId = familyId,
                        familyName = family.name
                    )
                    
                    // Send expired notification for each item
                    notificationService.sendExpiredItemNotification(familyId, notification)
                    
                    item.status = com.smartgrocery.entity.FridgeItemStatus.EXPIRED
                }
            }
            
            fridgeItemRepository.saveAll(expiredItems)
        }

        logger.info("Daily expiration check completed")
    }

    /**
     * Runs every hour to check for newly expired items
     */
    @Scheduled(cron = "0 0 * * * *")
    fun updateExpiredItemsStatus() {
        val today = LocalDate.now()
        val expiredItems = fridgeItemRepository.findExpiredWithDetails(today)

        if (expiredItems.isNotEmpty()) {
            logger.info("Updating ${expiredItems.size} expired items")
            expiredItems.forEach { item ->
                item.status = com.smartgrocery.entity.FridgeItemStatus.EXPIRED
            }
            fridgeItemRepository.saveAll(expiredItems)
        }
    }
}

