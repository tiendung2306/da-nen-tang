package com.smartgrocery.controller

import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.notification.*
import com.smartgrocery.scheduler.ExpirationNotificationScheduler
import com.smartgrocery.service.NotificationManagementService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Notification management APIs")
class NotificationController(
    private val notificationManagementService: NotificationManagementService,
    private val expirationNotificationScheduler: ExpirationNotificationScheduler
) {

    @GetMapping
    @Operation(summary = "Get notifications with pagination")
    fun getNotifications(
        @RequestParam(required = false) unreadOnly: Boolean?,
        @PageableDefault(size = 20, sort = ["createdAt"]) pageable: Pageable
    ): ResponseEntity<ApiResponse<PaginatedNotifications>> {
        val notifications = notificationManagementService.getNotifications(unreadOnly, pageable)
        return ResponseEntity.ok(ApiResponse.success(notifications))
    }

    @GetMapping("/count")
    @Operation(summary = "Get notification count")
    fun getNotificationCount(): ResponseEntity<ApiResponse<NotificationCountResponse>> {
        val count = notificationManagementService.getNotificationCount()
        return ResponseEntity.ok(ApiResponse.success(count))
    }

    @PostMapping("/mark-read")
    @Operation(summary = "Mark notifications as read")
    fun markAsRead(
        @Valid @RequestBody request: MarkAsReadRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        notificationManagementService.markAsRead(request.notificationIds)
        return ResponseEntity.ok(ApiResponse.success("Notifications marked as read"))
    }

    @PostMapping("/mark-all-read")
    @Operation(summary = "Mark all notifications as read")
    fun markAllAsRead(): ResponseEntity<ApiResponse<Nothing>> {
        notificationManagementService.markAllAsRead()
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read"))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a notification")
    fun deleteNotification(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        notificationManagementService.deleteNotification(id)
        return ResponseEntity.ok(ApiResponse.success("Notification deleted"))
    }

    // ============ TEST ENDPOINTS (for development/testing) ============

    @PostMapping("/test/check-expiring")
    @Operation(summary = "Manually trigger expiring items check (3-day threshold)")
    fun triggerExpiringCheck(): ResponseEntity<ApiResponse<Nothing>> {
        expirationNotificationScheduler.checkExpiringItems()
        return ResponseEntity.ok(ApiResponse.success("Expiring items check completed"))
    }

    @PostMapping("/test/check-critical")
    @Operation(summary = "Manually trigger critical items check (24-hour threshold)")
    fun triggerCriticalCheck(): ResponseEntity<ApiResponse<Nothing>> {
        expirationNotificationScheduler.checkCriticalExpiringItems()
        return ResponseEntity.ok(ApiResponse.success("Critical items check completed"))
    }

    @PostMapping("/test/check-expired")
    @Operation(summary = "Manually trigger expired items check")
    fun triggerExpiredCheck(): ResponseEntity<ApiResponse<Nothing>> {
        expirationNotificationScheduler.checkExpiredItems()
        return ResponseEntity.ok(ApiResponse.success("Expired items check completed"))
    }
}
