package com.smartgrocery.repository

import com.smartgrocery.entity.MealPlan
import com.smartgrocery.entity.MealType
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface MealPlanRepository : JpaRepository<MealPlan, Long> {
    
    @EntityGraph(attributePaths = ["createdBy"])
    @Query("SELECT mp FROM MealPlan mp WHERE mp.family.id = :familyId AND mp.date = :date")
    fun findByFamilyIdAndDateWithCreatedBy(familyId: Long, date: LocalDate): List<MealPlan>
    
    fun findByFamilyIdAndDateAndMealType(familyId: Long, date: LocalDate, mealType: MealType): MealPlan?
    
    @Query("""
        SELECT mp FROM MealPlan mp 
        LEFT JOIN FETCH mp.items i 
        LEFT JOIN FETCH mp.createdBy 
        LEFT JOIN FETCH i.recipe r 
        LEFT JOIN FETCH r.createdBy 
        WHERE mp.family.id = :familyId AND mp.date = :date AND mp.mealType = :mealType
    """)
    fun findByFamilyIdAndDateAndMealTypeWithItems(familyId: Long, date: LocalDate, mealType: MealType): MealPlan?

    @Query("SELECT mp FROM MealPlan mp LEFT JOIN FETCH mp.items i LEFT JOIN FETCH mp.createdBy LEFT JOIN FETCH i.recipe r LEFT JOIN FETCH r.createdBy WHERE mp.id = :id")
    fun findByIdWithItems(id: Long): MealPlan?

    @EntityGraph(attributePaths = ["createdBy"])
    @Query("""
        SELECT mp FROM MealPlan mp 
        WHERE mp.family.id = :familyId 
        AND mp.date BETWEEN :startDate AND :endDate 
        ORDER BY mp.date ASC, mp.mealType ASC
    """)
    fun findByFamilyIdAndDateBetweenWithCreatedBy(familyId: Long, startDate: LocalDate, endDate: LocalDate): List<MealPlan>

    @Query("""
        SELECT DISTINCT mp FROM MealPlan mp 
        LEFT JOIN FETCH mp.items i
        LEFT JOIN FETCH mp.createdBy
        LEFT JOIN FETCH i.recipe r
        LEFT JOIN FETCH r.createdBy
        WHERE mp.family.id = :familyId 
        AND mp.date BETWEEN :startDate AND :endDate 
        ORDER BY mp.date ASC
    """)
    fun findByFamilyIdAndDateBetweenWithItems(familyId: Long, startDate: LocalDate, endDate: LocalDate): List<MealPlan>

    fun existsByFamilyIdAndDateAndMealType(familyId: Long, date: LocalDate, mealType: MealType): Boolean
}

