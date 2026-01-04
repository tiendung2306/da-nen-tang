package com.smartgrocery.dto.product

import com.smartgrocery.dto.category.CategoryResponse

// DTO for creating product - image is uploaded separately via multipart
data class CreateProductRequest(
    val name: String,
    val defaultUnit: String,
    val avgShelfLife: Int? = null,
    val description: String? = null,
    val categoryIds: List<Long> = emptyList()
)

// DTO for updating product - image is uploaded separately via multipart
data class UpdateProductRequest(
    val name: String? = null,
    val defaultUnit: String? = null,
    val avgShelfLife: Int? = null,
    val description: String? = null,
    val categoryIds: List<Long>? = null,
    val isActive: Boolean? = null
)

data class ProductResponse(
    val id: Long,
    val name: String,
    val imageUrl: String?,
    val defaultUnit: String,
    val avgShelfLife: Int?,
    val description: String?,
    val isActive: Boolean,
    val categories: List<CategoryResponse> = emptyList()
)

data class ProductSimpleResponse(
    val id: Long,
    val name: String,
    val imageUrl: String?,
    val defaultUnit: String
)

