package com.smartgrocery.service

import com.smartgrocery.dto.common.PageResponse
import com.smartgrocery.dto.family.UserSimpleResponse
import com.smartgrocery.dto.product.ProductSimpleResponse
import com.smartgrocery.dto.shopping.*
import com.smartgrocery.entity.ShoppingItem
import com.smartgrocery.entity.ShoppingList
import com.smartgrocery.entity.ShoppingListStatus
import com.smartgrocery.exception.*
import com.smartgrocery.repository.*
import com.smartgrocery.security.CustomUserDetails
import org.springframework.data.domain.Pageable
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class ShoppingListService(
    private val shoppingListRepository: ShoppingListRepository,
    private val shoppingItemRepository: ShoppingItemRepository,
    private val familyRepository: FamilyRepository,
    private val familyMemberRepository: FamilyMemberRepository,
    private val userRepository: UserRepository,
    private val productRepository: MasterProductRepository
) {

    @Transactional
    fun createShoppingList(request: CreateShoppingListRequest): ShoppingListDetailResponse {
        val currentUser = getCurrentUser()
        checkFamilyMembership(request.familyId, currentUser.id)

        val family = familyRepository.findById(request.familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        val user = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val assignedTo = request.assignedToId?.let {
            val assignedUser = userRepository.findById(it)
                .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }
            // Verify assigned user is a member of the family
            checkFamilyMembership(request.familyId, it)
            assignedUser
        }

        val shoppingList = ShoppingList(
            family = family,
            name = request.name,
            description = request.description,
            createdBy = user,
            assignedTo = assignedTo
        )

        val savedList = shoppingListRepository.save(shoppingList)

        // Add items if provided
        val items = request.items.map { itemRequest ->
            createShoppingItem(savedList, itemRequest)
        }
        shoppingItemRepository.saveAll(items)
        savedList.items.addAll(items)

        return toDetailResponse(savedList)
    }

    fun getShoppingListsByFamily(familyId: Long, pageable: Pageable): PageResponse<ShoppingListResponse> {
        val currentUser = getCurrentUser()
        checkFamilyMembership(familyId, currentUser.id)

        val page = shoppingListRepository.findByFamilyIdWithDetails(familyId, pageable)
        return PageResponse.from(page) { toResponse(it) }
    }

    fun getShoppingListById(listId: Long): ShoppingListDetailResponse {
        val currentUser = getCurrentUser()
        val list = shoppingListRepository.findByIdWithItems(listId)
            ?: throw ResourceNotFoundException(ErrorCode.SHOPPING_LIST_NOT_FOUND)

        checkFamilyMembership(list.family.id!!, currentUser.id)
        return toDetailResponse(list)
    }

    @Transactional
    fun updateShoppingList(listId: Long, request: UpdateShoppingListRequest): ShoppingListDetailResponse {
        val currentUser = getCurrentUser()
        val list = shoppingListRepository.findByIdWithItems(listId)
            ?: throw ResourceNotFoundException(ErrorCode.SHOPPING_LIST_NOT_FOUND)

        checkFamilyMembership(list.family.id!!, currentUser.id)
        checkVersion(list.version, request.version)

        val oldStatus = list.status

        request.name?.let { list.name = it }
        request.description?.let { list.description = it }
        request.status?.let { newStatus ->
            list.status = newStatus
            
            // Handle status change logic for shopping items
            when {
                // When marking as COMPLETED -> mark all items as bought (100%)
                newStatus == ShoppingListStatus.COMPLETED && oldStatus != ShoppingListStatus.COMPLETED -> {
                    list.items.forEach { item ->
                        if (!item.isBought) {
                            item.isBought = true
                            val user = userRepository.findById(currentUser.id)
                                .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }
                            item.boughtBy = user
                        }
                    }
                }
                // When changing from COMPLETED to PLANNING or SHOPPING -> mark all items as not bought (0%)
                oldStatus == ShoppingListStatus.COMPLETED && 
                (newStatus == ShoppingListStatus.PLANNING || newStatus == ShoppingListStatus.SHOPPING) -> {
                    list.items.forEach { item ->
                        item.isBought = false
                        item.boughtBy = null
                    }
                }
            }
        }
        request.assignedToId?.let { assignedToId ->
            val assignedUser = userRepository.findById(assignedToId)
                .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }
            // Verify assigned user is a member of the family
            checkFamilyMembership(list.family.id!!, assignedToId)
            list.assignedTo = assignedUser
        }

        val savedList = shoppingListRepository.save(list)
        return toDetailResponse(savedList)
    }

    @Transactional
    fun deleteShoppingList(listId: Long) {
        val currentUser = getCurrentUser()
        val list = shoppingListRepository.findById(listId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.SHOPPING_LIST_NOT_FOUND) }

        checkFamilyMembership(list.family.id!!, currentUser.id)
        shoppingListRepository.delete(list)
    }

    @Transactional
    fun addItemToList(request: AddItemToListRequest): ShoppingItemResponse {
        val currentUser = getCurrentUser()
        val list = shoppingListRepository.findById(request.listId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.SHOPPING_LIST_NOT_FOUND) }

        checkFamilyMembership(list.family.id!!, currentUser.id)

        val item = createShoppingItem(list, request.item)
        val savedItem = shoppingItemRepository.save(item)
        return toItemResponse(savedItem)
    }

    @Transactional
    fun addItemsToList(request: BulkAddItemsRequest): List<ShoppingItemResponse> {
        val currentUser = getCurrentUser()
        val list = shoppingListRepository.findById(request.listId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.SHOPPING_LIST_NOT_FOUND) }

        checkFamilyMembership(list.family.id!!, currentUser.id)

        val items = request.items.map { createShoppingItem(list, it) }
        val savedItems = shoppingItemRepository.saveAll(items)
        return savedItems.map { toItemResponse(it) }
    }

    @Transactional
    fun updateShoppingItem(itemId: Long, request: UpdateShoppingItemRequest): ShoppingItemResponse {
        val currentUser = getCurrentUser()
        val item = shoppingItemRepository.findById(itemId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.SHOPPING_ITEM_NOT_FOUND) }

        checkFamilyMembership(item.shoppingList.family.id!!, currentUser.id)
        checkVersion(item.version, request.version)

        request.quantity?.let { item.quantity = it }
        request.unit?.let { item.unit = it }
        request.note?.let { item.note = it }
        request.price?.let { item.price = it }

        request.isBought?.let { isBought ->
            item.isBought = isBought
            if (isBought) {
                val user = userRepository.findById(currentUser.id)
                    .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }
                item.boughtBy = user
            } else {
                item.boughtBy = null
            }
        }

        request.assignedToId?.let { assignedToId ->
            val assignedUser = userRepository.findById(assignedToId)
                .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }
            item.assignedTo = assignedUser
        }

        val savedItem = shoppingItemRepository.save(item)
        return toItemResponse(savedItem)
    }

    @Transactional
    fun deleteShoppingItem(itemId: Long) {
        val currentUser = getCurrentUser()
        val item = shoppingItemRepository.findById(itemId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.SHOPPING_ITEM_NOT_FOUND) }

        checkFamilyMembership(item.shoppingList.family.id!!, currentUser.id)
        shoppingItemRepository.delete(item)
    }

    fun getActiveListsByFamily(familyId: Long): List<ShoppingListResponse> {
        val currentUser = getCurrentUser()
        checkFamilyMembership(familyId, currentUser.id)

        val activeStatuses = listOf(ShoppingListStatus.PLANNING, ShoppingListStatus.SHOPPING)
        return shoppingListRepository.findByFamilyIdAndStatusInWithDetails(familyId, activeStatuses)
            .map { toResponse(it) }
    }

    private fun createShoppingItem(list: ShoppingList, request: CreateShoppingItemRequest): ShoppingItem {
        if (request.masterProductId == null && request.customProductName.isNullOrBlank()) {
            throw ValidationException(ErrorCode.INVALID_PRODUCT_SPECIFICATION.message)
        }

        val masterProduct = request.masterProductId?.let { 
            productRepository.findById(it)
                .orElseThrow { ResourceNotFoundException(ErrorCode.PRODUCT_NOT_FOUND) }
        }

        val assignedTo = request.assignedToId?.let {
            userRepository.findById(it).orElse(null)
        }

        return ShoppingItem(
            shoppingList = list,
            masterProduct = masterProduct,
            customProductName = request.customProductName,
            quantity = request.quantity,
            unit = request.unit,
            note = request.note,
            assignedTo = assignedTo
        )
    }

    private fun checkFamilyMembership(familyId: Long, userId: Long) {
        if (!familyMemberRepository.existsByFamilyIdAndUserId(familyId, userId)) {
            throw ForbiddenException("You are not a member of this family")
        }
    }

    private fun checkVersion(currentVersion: Long, requestVersion: Long) {
        if (currentVersion != requestVersion) {
            throw ConcurrencyException()
        }
    }

    private fun getCurrentUser(): CustomUserDetails {
        val authentication = SecurityContextHolder.getContext().authentication
        return authentication.principal as CustomUserDetails
    }

    private fun toResponse(list: ShoppingList): ShoppingListResponse {
        val itemCount = shoppingItemRepository.countByListId(list.id!!).toInt()
        val boughtCount = shoppingItemRepository.countBoughtByListId(list.id!!).toInt()

        return ShoppingListResponse(
            id = list.id!!,
            familyId = list.family.id!!,
            name = list.name,
            description = list.description,
            status = list.status,
            createdBy = UserSimpleResponse(
                id = list.createdBy.id!!,
                username = list.createdBy.username,
                fullName = list.createdBy.fullName
            ),
            assignedTo = list.assignedTo?.let {
                UserSimpleResponse(
                    id = it.id!!,
                    username = it.username,
                    fullName = it.fullName
                )
            },
            version = list.version,
            itemCount = itemCount,
            boughtCount = boughtCount,
            createdAt = list.createdAt,
            updatedAt = list.updatedAt
        )
    }

    private fun toDetailResponse(list: ShoppingList): ShoppingListDetailResponse {
        return ShoppingListDetailResponse(
            id = list.id!!,
            familyId = list.family.id!!,
            name = list.name,
            description = list.description,
            status = list.status,
            createdBy = UserSimpleResponse(
                id = list.createdBy.id!!,
                username = list.createdBy.username,
                fullName = list.createdBy.fullName
            ),
            assignedTo = list.assignedTo?.let {
                UserSimpleResponse(
                    id = it.id!!,
                    username = it.username,
                    fullName = it.fullName
                )
            },
            version = list.version,
            items = list.items.map { toItemResponse(it) },
            createdAt = list.createdAt,
            updatedAt = list.updatedAt
        )
    }

    private fun toItemResponse(item: ShoppingItem): ShoppingItemResponse {
        return ShoppingItemResponse(
            id = item.id!!,
            listId = item.shoppingList.id!!,
            productName = item.getProductName(),
            masterProduct = item.masterProduct?.let {
                ProductSimpleResponse(
                    id = it.id!!,
                    name = it.name,
                    imageUrl = it.imageUrl,
                    defaultUnit = it.defaultUnit
                )
            },
            customProductName = item.customProductName,
            quantity = item.quantity,
            unit = item.unit,
            isBought = item.isBought,
            note = item.note,
            price = item.price,
            assignedTo = item.assignedTo?.let {
                UserSimpleResponse(
                    id = it.id!!,
                    username = it.username,
                    fullName = it.fullName
                )
            },
            boughtBy = item.boughtBy?.let {
                UserSimpleResponse(
                    id = it.id!!,
                    username = it.username,
                    fullName = it.fullName
                )
            },
            version = item.version,
            createdAt = item.createdAt,
            updatedAt = item.updatedAt
        )
    }
}

