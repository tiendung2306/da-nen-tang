package com.smartgrocery.controller

import com.smartgrocery.dto.common.ApiResponse
import com.smartgrocery.dto.common.PageResponse
import com.smartgrocery.dto.product.*
import com.smartgrocery.service.ProductService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping("/api/v1/master-products")
@Tag(name = "Master Products", description = "Product catalog management APIs")
class ProductController(
    private val productService: ProductService
) {

    @GetMapping
    @Operation(summary = "Get all products with pagination")
    fun getAllProducts(
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> {
        val products = productService.getAllProducts(pageable)
        return ResponseEntity.ok(ApiResponse.success(products))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product by ID")
    fun getProductById(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<ProductResponse>> {
        val product = productService.getProductById(id)
        return ResponseEntity.ok(ApiResponse.success(product))
    }

    @GetMapping("/search")
    @Operation(summary = "Search products by name")
    fun searchProducts(
        @RequestParam name: String,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> {
        val products = productService.searchProducts(name, pageable)
        return ResponseEntity.ok(ApiResponse.success(products))
    }

    @GetMapping("/by-category/{categoryId}")
    @Operation(summary = "Get products by category")
    fun getProductsByCategory(
        @PathVariable categoryId: Long,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> {
        val products = productService.getProductsByCategory(categoryId, pageable)
        return ResponseEntity.ok(ApiResponse.success(products))
    }

    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create a new product with image upload (Admin only)")
    fun createProduct(
        @RequestParam name: String,
        @RequestParam defaultUnit: String,
        @RequestParam(required = false) avgShelfLife: Int?,
        @RequestParam(required = false) description: String?,
        @RequestParam(required = false) categoryIds: List<Long>?,
        @RequestParam(required = false) image: MultipartFile?
    ): ResponseEntity<ApiResponse<ProductResponse>> {
        val request = CreateProductRequest(
            name = name,
            defaultUnit = defaultUnit,
            avgShelfLife = avgShelfLife,
            description = description,
            categoryIds = categoryIds ?: emptyList()
        )
        val product = productService.createProduct(request, image)
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.created(product))
    }

    @PutMapping("/{id}", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update a product with image upload (Admin only)")
    fun updateProduct(
        @PathVariable id: Long,
        @RequestParam(required = false) name: String?,
        @RequestParam(required = false) defaultUnit: String?,
        @RequestParam(required = false) avgShelfLife: Int?,
        @RequestParam(required = false) description: String?,
        @RequestParam(required = false) categoryIds: List<Long>?,
        @RequestParam(required = false) isActive: Boolean?,
        @RequestParam(required = false) image: MultipartFile?
    ): ResponseEntity<ApiResponse<ProductResponse>> {
        val request = UpdateProductRequest(
            name = name,
            defaultUnit = defaultUnit,
            avgShelfLife = avgShelfLife,
            description = description,
            categoryIds = categoryIds,
            isActive = isActive
        )
        val product = productService.updateProduct(id, request, image)
        return ResponseEntity.ok(ApiResponse.success(product, "Product updated successfully"))
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete a product (Admin only)")
    fun deleteProduct(
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        productService.deleteProduct(id)
        return ResponseEntity.ok(ApiResponse.success("Product deleted successfully"))
    }
}

