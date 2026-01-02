package com.smartgrocery.service

import com.smartgrocery.dto.family.UserSimpleResponse
import com.smartgrocery.dto.mealplan.*
import com.smartgrocery.entity.MealItem
import com.smartgrocery.entity.MealPlan
import com.smartgrocery.entity.MealType
import com.smartgrocery.exception.*
import com.smartgrocery.repository.*
import com.smartgrocery.security.CustomUserDetails
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate

@Service
class MealPlanService(
    private val mealPlanRepository: MealPlanRepository,
    private val mealItemRepository: MealItemRepository,
    private val familyRepository: FamilyRepository,
    private val familyMemberRepository: FamilyMemberRepository,
    private val userRepository: UserRepository,
    private val recipeRepository: RecipeRepository,
    private val recipeService: RecipeService
) {

    @Transactional
    fun createMealPlan(request: CreateMealPlanRequest): MealPlanDetailResponse {
        val currentUser = getCurrentUser()
        checkFamilyMembership(request.familyId, currentUser.id)

        // Check if plan already exists - if so, add items to existing plan instead of throwing error
        val existingPlan = mealPlanRepository.findByFamilyIdAndDateAndMealTypeWithItems(request.familyId, request.date, request.mealType)
        if (existingPlan != null) {
            // Add items to existing plan instead of creating new one
            val maxOrder = mealItemRepository.findMaxOrderIndex(existingPlan.id!!) ?: -1
            val items = request.items.mapIndexed { index, itemRequest ->
                createMealItem(existingPlan, itemRequest, maxOrder + 1 + index)
            }
            mealItemRepository.saveAll(items)
            existingPlan.items.addAll(items)
            return toDetailResponse(existingPlan)
        }

        val family = familyRepository.findById(request.familyId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.FAMILY_NOT_FOUND) }

        val user = userRepository.findById(currentUser.id)
            .orElseThrow { ResourceNotFoundException(ErrorCode.USER_NOT_FOUND) }

        val mealPlan = MealPlan(
            family = family,
            date = request.date,
            mealType = request.mealType,
            note = request.note,
            createdBy = user
        )

        val savedPlan = mealPlanRepository.save(mealPlan)

        // Add meal items
        val items = request.items.mapIndexed { index, itemRequest ->
            createMealItem(savedPlan, itemRequest, index)
        }
        mealItemRepository.saveAll(items)
        savedPlan.items.addAll(items)

        return toDetailResponse(savedPlan)
    }

    fun getMealPlanById(mealPlanId: Long): MealPlanDetailResponse {
        val currentUser = getCurrentUser()
        val mealPlan = mealPlanRepository.findByIdWithItems(mealPlanId)
            ?: throw ResourceNotFoundException(ErrorCode.MEAL_PLAN_NOT_FOUND)

        checkFamilyMembership(mealPlan.family.id!!, currentUser.id)
        return toDetailResponse(mealPlan)
    }

    fun getMealPlansByDateRange(familyId: Long, startDate: LocalDate, endDate: LocalDate): List<MealPlanDetailResponse> {
        val currentUser = getCurrentUser()
        checkFamilyMembership(familyId, currentUser.id)

        val plans = mealPlanRepository.findByFamilyIdAndDateBetweenWithItems(familyId, startDate, endDate)
        return plans.map { toDetailResponse(it) }
    }

    fun getDailyMealPlan(familyId: Long, date: LocalDate): DailyMealPlanResponse {
        val currentUser = getCurrentUser()
        checkFamilyMembership(familyId, currentUser.id)

        // Fetch all meal plans for the day with items in a single query
        val plans = mealPlanRepository.findByFamilyIdAndDateBetweenWithItems(familyId, date, date)
        val plansByType = plans.associateBy { it.mealType }

        return DailyMealPlanResponse(
            date = date,
            breakfast = plansByType[MealType.BREAKFAST]?.let { toDetailResponse(it) },
            lunch = plansByType[MealType.LUNCH]?.let { toDetailResponse(it) },
            dinner = plansByType[MealType.DINNER]?.let { toDetailResponse(it) },
            snack = plansByType[MealType.SNACK]?.let { toDetailResponse(it) }
        )
    }

    fun getWeeklyMealPlan(familyId: Long, startDate: LocalDate): WeeklyMealPlanResponse {
        val currentUser = getCurrentUser()
        checkFamilyMembership(familyId, currentUser.id)

        val endDate = startDate.plusDays(6)
        val days = (0..6).map { offset ->
            val date = startDate.plusDays(offset.toLong())
            getDailyMealPlan(familyId, date)
        }

        return WeeklyMealPlanResponse(
            startDate = startDate,
            endDate = endDate,
            days = days
        )
    }

    @Transactional
    fun updateMealPlan(mealPlanId: Long, request: UpdateMealPlanRequest): MealPlanDetailResponse {
        val currentUser = getCurrentUser()
        val mealPlan = mealPlanRepository.findByIdWithItems(mealPlanId)
            ?: throw ResourceNotFoundException(ErrorCode.MEAL_PLAN_NOT_FOUND)

        checkFamilyMembership(mealPlan.family.id!!, currentUser.id)

        request.note?.let { mealPlan.note = it }

        // Update items if provided
        request.items?.let { itemRequests ->
            // Remove old items
            mealPlan.items.clear()
            mealItemRepository.deleteByMealPlanId(mealPlanId)

            // Add new items
            val items = itemRequests.mapIndexed { index, itemRequest ->
                createMealItem(mealPlan, itemRequest, index)
            }
            mealItemRepository.saveAll(items)
            mealPlan.items.addAll(items)
        }

        val savedPlan = mealPlanRepository.save(mealPlan)
        return toDetailResponse(savedPlan)
    }

    @Transactional
    fun addMealItem(request: AddMealItemRequest): MealItemResponse {
        val currentUser = getCurrentUser()
        val mealPlan = mealPlanRepository.findById(request.mealPlanId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.MEAL_PLAN_NOT_FOUND) }

        checkFamilyMembership(mealPlan.family.id!!, currentUser.id)

        val maxOrder = mealItemRepository.findMaxOrderIndex(request.mealPlanId) ?: -1
        val item = createMealItem(mealPlan, request.item, maxOrder + 1)
        val savedItem = mealItemRepository.save(item)

        return toItemResponse(savedItem)
    }

    @Transactional
    fun deleteMealItem(itemId: Long) {
        val currentUser = getCurrentUser()
        val item = mealItemRepository.findById(itemId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.MEAL_ITEM_NOT_FOUND) }

        checkFamilyMembership(item.mealPlan.family.id!!, currentUser.id)
        mealItemRepository.delete(item)
    }

    @Transactional
    fun deleteMealPlan(mealPlanId: Long) {
        val currentUser = getCurrentUser()
        val mealPlan = mealPlanRepository.findById(mealPlanId)
            .orElseThrow { ResourceNotFoundException(ErrorCode.MEAL_PLAN_NOT_FOUND) }

        checkFamilyMembership(mealPlan.family.id!!, currentUser.id)
        mealPlanRepository.delete(mealPlan)
    }

    private fun createMealItem(mealPlan: MealPlan, request: CreateMealItemRequest, orderIndex: Int): MealItem {
        val recipe = request.recipeId?.let {
            recipeRepository.findById(it)
                .orElseThrow { ResourceNotFoundException(ErrorCode.RECIPE_NOT_FOUND) }
        }

        return MealItem(
            mealPlan = mealPlan,
            recipe = recipe,
            customDishName = request.customDishName,
            servings = request.servings,
            orderIndex = request.orderIndex.takeIf { it > 0 } ?: orderIndex,
            note = request.note
        )
    }

    private fun checkFamilyMembership(familyId: Long, userId: Long) {
        if (!familyMemberRepository.existsByFamilyIdAndUserId(familyId, userId)) {
            throw ForbiddenException("You are not a member of this family")
        }
    }

    private fun getCurrentUser(): CustomUserDetails {
        val authentication = SecurityContextHolder.getContext().authentication
        return authentication.principal as CustomUserDetails
    }

    private fun toResponse(mealPlan: MealPlan): MealPlanResponse {
        return MealPlanResponse(
            id = mealPlan.id!!,
            familyId = mealPlan.family.id!!,
            date = mealPlan.date,
            mealType = mealPlan.mealType,
            note = mealPlan.note,
            createdBy = UserSimpleResponse(
                id = mealPlan.createdBy.id!!,
                username = mealPlan.createdBy.username,
                fullName = mealPlan.createdBy.fullName
            ),
            itemCount = mealPlan.items.size,
            createdAt = mealPlan.createdAt,
            updatedAt = mealPlan.updatedAt
        )
    }

    private fun toDetailResponse(mealPlan: MealPlan): MealPlanDetailResponse {
        return MealPlanDetailResponse(
            id = mealPlan.id!!,
            familyId = mealPlan.family.id!!,
            date = mealPlan.date,
            mealType = mealPlan.mealType,
            note = mealPlan.note,
            createdBy = UserSimpleResponse(
                id = mealPlan.createdBy.id!!,
                username = mealPlan.createdBy.username,
                fullName = mealPlan.createdBy.fullName
            ),
            items = mealPlan.items.sortedBy { it.orderIndex }.map { toItemResponse(it) },
            createdAt = mealPlan.createdAt,
            updatedAt = mealPlan.updatedAt
        )
    }

    private fun toItemResponse(item: MealItem): MealItemResponse {
        return MealItemResponse(
            id = item.id!!,
            mealPlanId = item.mealPlan.id!!,
            dishName = item.getDishName(),
            recipe = item.recipe?.let { recipeService.toResponse(it) },
            customDishName = item.customDishName,
            servings = item.servings,
            orderIndex = item.orderIndex,
            note = item.note,
            createdAt = item.createdAt,
            updatedAt = item.updatedAt
        )
    }
}

