package com.smartgrocery.dto.ai

import com.fasterxml.jackson.annotation.JsonProperty

// Request DTOs
data class AIRecipeSuggestionRequest(
    val availableIngredients: List<String>,
    val dietaryPreference: String? = null,
    val cuisineType: String? = null,
    val servings: Int? = null
)

// Response DTOs
data class RecipeIngredientDTO(
    val name: String,
    val quantity: Double,
    val unit: String,
    val note: String? = null,
    val isOptional: Boolean = false
)

data class AIRecipeSuggestionResponse(
    val title: String,
    val description: String,
    val difficulty: String, // EASY, MEDIUM, HARD
    val servings: Int,
    val prepTime: Int, // minutes
    val cookTime: Int, // minutes
    val ingredients: List<RecipeIngredientDTO>,
    val instructions: List<String>, // Array of instruction steps
    val notes: String? = null
)

// Internal DTOs for Fireworks API
internal data class FireworksMessage(
    val role: String,
    val content: String
)

internal data class FireworksRequest(
    val model: String,
    val messages: List<FireworksMessage>,
    val temperature: Double = 0.7,
    @JsonProperty("max_tokens")
    val maxTokens: Int = 2000,
    @JsonProperty("top_p")
    val topP: Double = 0.9
)

internal data class FireworksChoice(
    val message: FireworksMessage,
    @JsonProperty("finish_reason")
    val finishReason: String
)

internal data class FireworksUsage(
    @JsonProperty("prompt_tokens")
    val promptTokens: Int,
    @JsonProperty("completion_tokens")
    val completionTokens: Int,
    @JsonProperty("total_tokens")
    val totalTokens: Int
)

internal data class FireworksResponse(
    val id: String,
    val choices: List<FireworksChoice>,
    val usage: FireworksUsage
)
