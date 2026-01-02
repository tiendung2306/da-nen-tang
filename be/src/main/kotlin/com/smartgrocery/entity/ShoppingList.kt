package com.smartgrocery.entity

import jakarta.persistence.*

enum class ShoppingListStatus {
    PLANNING,
    SHOPPING,
    COMPLETED,
    CANCELLED
}

@Entity
@Table(name = "shopping_lists")
class ShoppingList(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    var family: Family,

    @Column(name = "name", nullable = false, length = 200)
    var name: String,

    @Column(name = "description", length = 500)
    var description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: ShoppingListStatus = ShoppingListStatus.PLANNING,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    var createdBy: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    var assignedTo: User? = null,

    @Version
    @Column(name = "version")
    var version: Long = 0,

    @OneToMany(mappedBy = "shoppingList", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var items: MutableList<ShoppingItem> = mutableListOf()
) : BaseEntity()

