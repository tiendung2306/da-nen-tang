package com.smartgrocery.service

import com.smartgrocery.dto.category.CategoryResponse
import com.smartgrocery.dto.common.PageResponse
import com.smartgrocery.dto.product.*
import com.smartgrocery.entity.MasterProduct
import com.smartgrocery.exception.ConflictException
import com.smartgrocery.exception.ErrorCode
import com.smartgrocery.exception.ResourceNotFoundException
import com.smartgrocery.repository.CategoryRepository
import com.smartgrocery.repository.MasterProductRepository
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile

@Service
class ProductService(
    private val productRepository: MasterProductRepository,
    private val categoryRepository: CategoryRepository,
    private val cloudinaryService: CloudinaryService
) {

    fun getAllProducts(pageable: Pageable): PageResponse<ProductResponse> {
        val page = productRepository.findByIsActiveTrueWithCategories(pageable)
        return PageResponse.from(page) { toResponse(it) }
    }

    fun getProductById(id: Long): ProductResponse {
        val product = productRepository.findByIdWithCategories(id)
            ?: throw ResourceNotFoundException(ErrorCode.PRODUCT_NOT_FOUND)
        return toResponse(product)
    }

    fun searchProducts(name: String, pageable: Pageable): PageResponse<ProductResponse> {
        val page = productRepository.findByNameContainingIgnoreCaseAndIsActiveTrueWithCategories(name, pageable)
        return PageResponse.from(page) { toResponse(it) }
    }

    fun getProductsByCategory(categoryId: Long, pageable: Pageable): PageResponse<ProductResponse> {
        val page = productRepository.findByCategoryIdWithCategories(categoryId, pageable)
        return PageResponse.from(page) { toResponse(it) }
    }

    @Transactional
    fun createProduct(request: CreateProductRequest, image: MultipartFile?): ProductResponse {
        if (productRepository.existsByName(request.name)) {
            throw ConflictException(ErrorCode.CONFLICT, "Product with this name already exists")
        }

        val categories = if (request.categoryIds.isNotEmpty()) {
            categoryRepository.findAllById(request.categoryIds).toMutableSet()
        } else {
            mutableSetOf()
        }

        // Upload image to Cloudinary if provided
        val imageUrl = image?.let { cloudinaryService.uploadFile(it, "products") }

        val product = MasterProduct(
            name = request.name,
            imageUrl = imageUrl,
            defaultUnit = request.defaultUnit,
            avgShelfLife = request.avgShelfLife,
            description = request.description,
            categories = categories
        )

        val savedProduct = productRepository.save(product)
        return toResponse(savedProduct)
    }

    @Transactional
    fun updateProduct(id: Long, request: UpdateProductRequest, image: MultipartFile?): ProductResponse {
        val product = productRepository.findByIdWithCategories(id)
            ?: throw ResourceNotFoundException(ErrorCode.PRODUCT_NOT_FOUND)

        request.name?.let { product.name = it }
        request.defaultUnit?.let { product.defaultUnit = it }
        request.avgShelfLife?.let { product.avgShelfLife = it }
        request.description?.let { product.description = it }
        request.isActive?.let { product.isActive = it }

        // Update image if provided
        image?.let {
            // Delete old image from Cloudinary if exists
            product.imageUrl?.let { oldUrl ->
                cloudinaryService.deleteFile(oldUrl)
            }
            product.imageUrl = cloudinaryService.uploadFile(it, "products")
        }

        request.categoryIds?.let { categoryIds ->
            val categories = if (categoryIds.isNotEmpty()) {
                categoryRepository.findAllById(categoryIds).toMutableSet()
            } else {
                mutableSetOf()
            }
            product.categories = categories
        }

        val savedProduct = productRepository.save(product)
        return toResponse(savedProduct)
    }

    @Transactional
    fun deleteProduct(id: Long) {
        val product = productRepository.findById(id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.PRODUCT_NOT_FOUND) }
        
        // Note: We don't delete image on soft delete
        // If you want to delete image, use hard delete or a separate endpoint
        
        // Soft delete
        product.isActive = false
        productRepository.save(product)
    }

    private fun toResponse(product: MasterProduct): ProductResponse {
        return ProductResponse(
            id = product.id!!,
            name = product.name,
            imageUrl = product.imageUrl,
            defaultUnit = product.defaultUnit,
            avgShelfLife = product.avgShelfLife,
            description = product.description,
            isActive = product.isActive,
            categories = product.categories.map { category ->
                CategoryResponse(
                    id = category.id!!,
                    name = category.name,
                    iconUrl = category.iconUrl,
                    description = category.description,
                    displayOrder = category.displayOrder,
                    isActive = category.isActive
                )
            }
        )
    }

    fun toSimpleResponse(product: MasterProduct): ProductSimpleResponse {
        return ProductSimpleResponse(
            id = product.id!!,
            name = product.name,
            imageUrl = product.imageUrl,
            defaultUnit = product.defaultUnit
        )
    }
}

