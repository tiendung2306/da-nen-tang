package com.smartgrocery.repository

import com.smartgrocery.entity.ShoppingList
import com.smartgrocery.entity.ShoppingListStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface ShoppingListRepository : JpaRepository<ShoppingList, Long> {
    
    @EntityGraph(attributePaths = ["family", "createdBy", "assignedTo"])
    @Query("SELECT sl FROM ShoppingList sl WHERE sl.family.id = :familyId")
    fun findByFamilyIdWithDetails(familyId: Long): List<ShoppingList>
    
    @EntityGraph(attributePaths = ["family", "createdBy", "assignedTo"])
    @Query("SELECT sl FROM ShoppingList sl WHERE sl.family.id = :familyId")
    fun findByFamilyIdWithDetails(familyId: Long, pageable: Pageable): Page<ShoppingList>
    
    fun findByFamilyIdAndStatus(familyId: Long, status: ShoppingListStatus): List<ShoppingList>

    @Query("SELECT sl FROM ShoppingList sl LEFT JOIN FETCH sl.items LEFT JOIN FETCH sl.createdBy LEFT JOIN FETCH sl.assignedTo WHERE sl.id = :id")
    fun findByIdWithItems(id: Long): ShoppingList?

    @EntityGraph(attributePaths = ["family", "createdBy", "assignedTo"])
    @Query("""
        SELECT sl FROM ShoppingList sl 
        WHERE sl.family.id = :familyId 
        AND sl.status IN :statuses 
        ORDER BY sl.createdAt DESC
    """)
    fun findByFamilyIdAndStatusInWithDetails(familyId: Long, statuses: List<ShoppingListStatus>): List<ShoppingList>

    @Query("SELECT sl FROM ShoppingList sl WHERE sl.createdBy.id = :userId ORDER BY sl.createdAt DESC")
    fun findByCreatedByUserId(userId: Long): List<ShoppingList>
}

