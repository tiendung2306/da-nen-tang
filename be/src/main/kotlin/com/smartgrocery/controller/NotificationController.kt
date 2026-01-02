package com.smartgrocery.controller

import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.notification.*
import com.smartgrocery.service.UserNotificationService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications", description = "Notification management APIs")
class NotificationController(
    private val userNotificationService: UserNotificationService
) {

    @GetMapping
    @Operation(summary = "Get notifications for current user")
    fun getNotifications(
        @RequestParam(defaultValue = "false") unreadOnly: Boolean,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<NotificationResponse>>> {
        val notifications = userNotificationService.getNotifications(unreadOnly, pageable)
        return ResponseEntity.ok(ApiResponse.success(notifications))
    }

    @GetMapping("/count")
    @Operation(summary = "Get notification count for current user")
    fun getNotificationCount(): ResponseEntity<ApiResponse<NotificationCountResponse>> {
        val count = userNotificationService.getNotificationCount()
        return ResponseEntity.ok(ApiResponse.success(count))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get notification by ID")
    fun getNotificationById(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<NotificationResponse>> {
        val notification = userNotificationService.getNotificationById(id)
        return ResponseEntity.ok(ApiResponse.success(notification))
    }

    @PostMapping("/mark-read")
    @Operation(summary = "Mark specific notifications as read")
    fun markAsRead(
        @RequestBody request: MarkNotificationsReadRequest
    ): ResponseEntity<ApiResponse<Map<String, Int>>> {
        val count = userNotificationService.markAsRead(request.ids)
        return ResponseEntity.ok(ApiResponse.success(mapOf("marked" to count)))
    }

    @PostMapping("/mark-all-read")
    @Operation(summary = "Mark all notifications as read")
    fun markAllAsRead(): ResponseEntity<ApiResponse<Map<String, Int>>> {
        val count = userNotificationService.markAllAsRead()
        return ResponseEntity.ok(ApiResponse.success(mapOf("marked" to count)))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a notification")
    fun deleteNotification(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Unit>> {
        userNotificationService.deleteNotification(id)
        return ResponseEntity.ok(ApiResponse.success(Unit))
    }
}
