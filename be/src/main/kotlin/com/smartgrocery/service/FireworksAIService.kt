package com.smartgrocery.service

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.smartgrocery.dto.ai.*
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.bodyToMono
import reactor.core.publisher.Mono
import java.time.Duration

@Service
class FireworksAIService(
    private val objectMapper: ObjectMapper,
    @Value("\${fireworks.ai.api-key}") private val apiKey: String,
    @Value("\${fireworks.ai.base-url:https://api.fireworks.ai/inference/v1}") private val baseUrl: String,
    @Value("\${fireworks.ai.model:accounts/fireworks/models/llama-v3p3-70b-instruct}") private val model: String
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    
    private val webClient: WebClient = WebClient.builder()
        .baseUrl(baseUrl)
        .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer $apiKey")
        .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
        .build()

    fun generateRecipeSuggestion(request: AIRecipeSuggestionRequest): Mono<AIRecipeSuggestionResponse> {
        logger.info("Generating recipe suggestion with ${request.availableIngredients.size} ingredients")
        
        val systemPrompt = buildSystemPrompt()
        val userPrompt = buildUserPrompt(request)
        
        val fireworksRequest = FireworksRequest(
            model = model,
            messages = listOf(
                FireworksMessage(role = "system", content = systemPrompt),
                FireworksMessage(role = "user", content = userPrompt)
            ),
            temperature = 0.7,
            maxTokens = 2000,
            topP = 0.9
        )

        return webClient.post()
            .uri("/chat/completions")
            .bodyValue(fireworksRequest)
            .retrieve()
            .bodyToMono<FireworksResponse>()
            .timeout(Duration.ofSeconds(60))
            .map { response ->
                logger.info("Received AI response: ${response.usage.totalTokens} tokens used")
                parseAIResponse(response.choices.first().message.content)
            }
            .doOnError { error ->
                logger.error("Error calling Fireworks AI", error)
            }
    }

    private fun buildSystemPrompt(): String {
        return """
Bạn là một chuyên gia về ẩm thực và dinh dưỡng. Nhiệm vụ của bạn là đề xuất công thức nấu ăn dựa trên nguyên liệu có sẵn.
Bạn phải trả về kết quả ở định dạng JSON với cấu trúc sau:
{
  "title": "Tên món ăn",
  "description": "Mô tả ngắn gọn về món ăn",
  "difficulty": "EASY|MEDIUM|HARD",
  "servings": số người ăn,
  "prepTime": thời gian chuẩn bị (phút),
  "cookTime": thời gian nấu (phút),
  "ingredients": [
    {
      "name": "tên nguyên liệu",
      "quantity": số lượng,
      "unit": "đơn vị",
      "note": "ghi chú (optional)",
      "isOptional": true/false
    }
  ],
  "instructions": ["Bước 1: ...", "Bước 2: ...", "Bước 3: ..."],
  "notes": "Ghi chú và mẹo hữu ích (optional)"
}
Chú ý: instructions phải là mảng các chuỗi, mỗi phần tử là một bước.
Chỉ trả về JSON, không thêm markdown hay text khác.
        """.trimIndent()
    }

    private fun buildUserPrompt(request: AIRecipeSuggestionRequest): String {
        val prompt = StringBuilder()
        prompt.appendLine("Hãy đề xuất một công thức nấu ăn với thông tin sau:")
        prompt.appendLine()
        prompt.appendLine("Nguyên liệu có sẵn:")
        request.availableIngredients.forEach { ingredient ->
            prompt.appendLine("- $ingredient")
        }
        
        if (request.servings != null) {
            prompt.appendLine()
            prompt.appendLine("Số người ăn: ${request.servings}")
        }
        
        if (!request.dietaryPreference.isNullOrBlank()) {
            prompt.appendLine()
            prompt.appendLine("Sở thích ăn uống: ${request.dietaryPreference}")
        }
        
        if (!request.cuisineType.isNullOrBlank()) {
            prompt.appendLine()
            prompt.appendLine("Loại ẩm thực: ${request.cuisineType}")
        }

        prompt.appendLine()
        prompt.appendLine("Yêu cầu:")
        prompt.appendLine("1. Sử dụng tối đa các nguyên liệu có sẵn từ danh sách trên")
        prompt.appendLine("2. Nếu thiếu nguyên liệu quan trọng, đánh dấu là \"isOptional\": false")
        prompt.appendLine("3. Các nguyên liệu phụ có thể đánh dấu là \"isOptional\": true")
        prompt.appendLine("4. Đưa ra hướng dẫn chi tiết, dễ hiểu")
        prompt.appendLine("5. Đánh giá độ khó dựa trên kỹ năng nấu ăn thông thường")
        
        return prompt.toString()
    }

    private fun parseAIResponse(content: String): AIRecipeSuggestionResponse {
        try {
            // Remove markdown code blocks if present
            var cleanContent = content.trim()
            if (cleanContent.startsWith("```json")) {
                cleanContent = cleanContent.substring(7)
            } else if (cleanContent.startsWith("```")) {
                cleanContent = cleanContent.substring(3)
            }
            if (cleanContent.endsWith("```")) {
                cleanContent = cleanContent.substring(0, cleanContent.length - 3)
            }
            cleanContent = cleanContent.trim()

            val response = objectMapper.readValue<AIRecipeSuggestionResponse>(cleanContent)
            
            // Validate required fields
            require(response.title.isNotBlank()) { "Title is required" }
            require(response.description.isNotBlank()) { "Description is required" }
            require(response.ingredients.isNotEmpty()) { "Ingredients are required" }
            require(response.instructions.isNotEmpty()) { "Instructions are required" }
            
            return response
        } catch (e: Exception) {
            logger.error("Failed to parse AI response: $content", e)
            throw IllegalArgumentException("Không thể phân tích phản hồi từ AI: ${e.message}")
        }
    }
}
