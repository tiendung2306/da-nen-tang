package com.smartgrocery.controller

import com.smartgrocery.dto.ai.AIRecipeSuggestionRequest
import com.smartgrocery.dto.ai.AIRecipeSuggestionResponse
import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.repository.UserRepository
import com.smartgrocery.security.JwtTokenProvider
import com.smartgrocery.service.FireworksAIService
import io.github.bucket4j.Bandwidth
import io.github.bucket4j.Bucket
import io.github.bucket4j.Refill
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.server.ResponseStatusException
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap

@RestController
@RequestMapping("/api/v1/ai")
@Tag(name = "AI Services", description = "AI-powered features")
class AIController(
    private val fireworksAIService: FireworksAIService,
    private val jwtTokenProvider: JwtTokenProvider,
    private val userRepository: UserRepository
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    
    // Rate limiting: 10 requests per user per day
    private val rateLimitBuckets = ConcurrentHashMap<Long, Bucket>()
    
    private fun getUserBucket(userId: Long): Bucket {
        return rateLimitBuckets.computeIfAbsent(userId) {
            val limit = Bandwidth.classic(10, Refill.intervally(10, Duration.ofDays(1)))
            Bucket.builder()
                .addLimit(limit)
                .build()
        }
    }

    @PostMapping("/recipes/suggest")
    @Operation(
        summary = "Generate recipe suggestion using AI",
        description = "Uses Fireworks AI to generate recipe based on available ingredients. Limited to 10 requests per user per day."
    )
    fun suggestRecipe(
        @RequestHeader("Authorization") authHeader: String,
        @Valid @RequestBody request: AIRecipeSuggestionRequest
    ): ResponseEntity<ApiResponse<AIRecipeSuggestionResponse>> {
        // Extract and validate JWT token
        val token = authHeader.removePrefix("Bearer ").trim()
        if (!jwtTokenProvider.validateToken(token)) {
            throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token không hợp lệ")
        }
        
        val username = jwtTokenProvider.getUsernameFromToken(token)
        val user = userRepository.findByUsername(username)
            ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Người dùng không tồn tại")
        val userId = user.id ?: throw ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "User ID không hợp lệ")
        
        // Rate limiting check
        val bucket = getUserBucket(userId)
        if (!bucket.tryConsume(1)) {
            logger.warn("User $userId exceeded AI rate limit")
            throw ResponseStatusException(
                HttpStatus.TOO_MANY_REQUESTS,
                "Bạn đã vượt quá giới hạn 10 yêu cầu AI mỗi ngày. Vui lòng thử lại sau."
            )
        }
        
        // Validate request
        if (request.availableIngredients.isEmpty()) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Vui lòng cung cấp ít nhất một nguyên liệu"
            )
        }
        
        logger.info("User $userId requesting AI recipe suggestion with ${request.availableIngredients.size} ingredients")
        
        return try {
            val response = fireworksAIService.generateRecipeSuggestion(request).block()
                ?: throw IllegalStateException("No response from AI service")
            ResponseEntity.ok(ApiResponse.success(response))
        } catch (error: Exception) {
            logger.error("AI service error for user $userId", error)
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error<AIRecipeSuggestionResponse>(
                    5000,
                    "Không thể tạo đề xuất công thức: ${error.message}"
                ))
        }
    }

    @GetMapping("/recipes/rate-limit")
    @Operation(summary = "Check remaining AI requests for current user")
    fun checkRateLimit(
        @RequestHeader("Authorization") authHeader: String
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val token = authHeader.removePrefix("Bearer ").trim()
        if (!jwtTokenProvider.validateToken(token)) {
            throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token không hợp lệ")
        }
        
        val username = jwtTokenProvider.getUsernameFromToken(token)
        val user = userRepository.findByUsername(username)
            ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Người dùng không tồn tại")
        val userId = user.id ?: throw ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "User ID không hợp lệ")
        val bucket = getUserBucket(userId)
        val availableTokens = bucket.availableTokens
        
        val response = mapOf(
            "remainingRequests" to availableTokens,
            "maxRequests" to 10,
            "resetPeriod" to "24 hours"
        )
        
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
