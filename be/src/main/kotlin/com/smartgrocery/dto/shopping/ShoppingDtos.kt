package com.smartgrocery.dto.shopping

import com.smartgrocery.dto.family.UserSimpleResponse
import com.smartgrocery.dto.product.ProductSimpleResponse
import com.smartgrocery.entity.ShoppingListStatus
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Positive
import jakarta.validation.constraints.Size
import java.math.BigDecimal
import java.time.Instant

// Shopping List DTOs
data class CreateShoppingListRequest(
    @field:NotNull(message = "Family ID is required")
    val familyId: Long,

    @field:NotBlank(message = "Shopping list name is required")
    @field:Size(max = 200, message = "Name must not exceed 200 characters")
    val name: String,

    @field:Size(max = 500, message = "Description must not exceed 500 characters")
    val description: String? = null,

    val assignedToId: Long? = null,

    @field:Valid
    val items: List<CreateShoppingItemRequest> = emptyList()
)

data class UpdateShoppingListRequest(
    @field:Size(max = 200, message = "Name must not exceed 200 characters")
    val name: String? = null,

    @field:Size(max = 500, message = "Description must not exceed 500 characters")
    val description: String? = null,

    val status: ShoppingListStatus? = null,

    val assignedToId: Long? = null,

    @field:NotNull(message = "Version is required for optimistic locking")
    val version: Long
)

data class ShoppingListResponse(
    val id: Long,
    val familyId: Long,
    val name: String,
    val description: String?,
    val status: ShoppingListStatus,
    val createdBy: UserSimpleResponse,
    val assignedTo: UserSimpleResponse?,
    val version: Long,
    val itemCount: Int,
    val boughtCount: Int,
    val createdAt: Instant,
    val updatedAt: Instant
)

data class ShoppingListDetailResponse(
    val id: Long,
    val familyId: Long,
    val name: String,
    val description: String?,
    val status: ShoppingListStatus,
    val createdBy: UserSimpleResponse,
    val assignedTo: UserSimpleResponse?,
    val version: Long,
    val items: List<ShoppingItemResponse>,
    val createdAt: Instant,
    val updatedAt: Instant
)

// Shopping Item DTOs
data class CreateShoppingItemRequest(
    val masterProductId: Long? = null,

    @field:Size(max = 200, message = "Custom product name must not exceed 200 characters")
    val customProductName: String? = null,

    @field:NotNull(message = "Quantity is required")
    @field:Positive(message = "Quantity must be positive")
    val quantity: BigDecimal,

    @field:NotBlank(message = "Unit is required")
    @field:Size(max = 50, message = "Unit must not exceed 50 characters")
    val unit: String,

    @field:Size(max = 255, message = "Note must not exceed 255 characters")
    val note: String? = null,

    val assignedToId: Long? = null
)

data class UpdateShoppingItemRequest(
    @field:Positive(message = "Quantity must be positive")
    val quantity: BigDecimal? = null,

    @field:Size(max = 50, message = "Unit must not exceed 50 characters")
    val unit: String? = null,

    val isBought: Boolean? = null,

    @field:Size(max = 255, message = "Note must not exceed 255 characters")
    val note: String? = null,

    @field:Positive(message = "Price must be positive")
    val price: BigDecimal? = null,

    val assignedToId: Long? = null,

    @field:NotNull(message = "Version is required for optimistic locking")
    val version: Long
)

data class ShoppingItemResponse(
    val id: Long,
    val listId: Long,
    val productName: String,
    val masterProduct: ProductSimpleResponse?,
    val customProductName: String?,
    val quantity: BigDecimal,
    val unit: String,
    val isBought: Boolean,
    val note: String?,
    val price: BigDecimal?,
    val assignedTo: UserSimpleResponse?,
    val boughtBy: UserSimpleResponse?,
    val version: Long,
    val createdAt: Instant,
    val updatedAt: Instant
)

data class AddItemToListRequest(
    @field:NotNull(message = "Shopping list ID is required")
    val listId: Long,

    @field:Valid
    val item: CreateShoppingItemRequest
)

data class BulkAddItemsRequest(
    @field:NotNull(message = "Shopping list ID is required")
    val listId: Long,

    @field:Valid
    val items: List<CreateShoppingItemRequest>
)

