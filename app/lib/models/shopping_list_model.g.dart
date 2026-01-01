// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingList _$ShoppingListFromJson(Map<String, dynamic> json) => ShoppingList(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      familyId: (json['familyId'] as num).toInt(),
      status: $enumDecode(_$ShoppingListStatusEnumMap, json['status'],
          unknownValue: ShoppingListStatus.DRAFT),
      version: (json['version'] as num?)?.toInt(),
      createdBy: json['createdBy'] == null
          ? null
          : UserInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCount: (json['itemCount'] as num?)?.toInt(),
      boughtCount: (json['boughtCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShoppingListToJson(ShoppingList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'familyId': instance.familyId,
      'status': _$ShoppingListStatusEnumMap[instance.status]!,
      'version': instance.version,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'items': instance.items,
      'itemCount': instance.itemCount,
      'boughtCount': instance.boughtCount,
    };

const _$ShoppingListStatusEnumMap = {
  ShoppingListStatus.DRAFT: 'DRAFT',
  ShoppingListStatus.SHOPPING: 'SHOPPING',
  ShoppingListStatus.COMPLETED: 'COMPLETED',
};

ShoppingItem _$ShoppingItemFromJson(Map<String, dynamic> json) => ShoppingItem(
      id: (json['id'] as num).toInt(),
      name: (json['productName'] ?? json['name'] ?? 'Unknown') as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: (json['unit'] ?? '') as String,
      note: json['note'] as String?,
      isBought: json['isBought'] as bool? ?? false,
      assignedTo: json['assignedTo'] == null
          ? null
          : UserInfo.fromJson(json['assignedTo'] as Map<String, dynamic>),
      boughtBy: json['boughtBy'] == null
          ? null
          : UserInfo.fromJson(json['boughtBy'] as Map<String, dynamic>),
      boughtAt: json['boughtAt'] == null
          ? null
          : DateTime.tryParse(json['boughtAt'].toString()),
      productId: (json['productId'] as num?)?.toInt(),
      productImageUrl: json['productImageUrl'] as String?,
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShoppingItemToJson(ShoppingItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productName': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'note': instance.note,
      'isBought': instance.isBought,
      'assignedTo': instance.assignedTo,
      'boughtBy': instance.boughtBy,
      'boughtAt': instance.boughtAt?.toIso8601String(),
      'productId': instance.productId,
      'productImageUrl': instance.productImageUrl,
      'version': instance.version,
    };

CreateShoppingListRequest _$CreateShoppingListRequestFromJson(
        Map<String, dynamic> json) =>
    CreateShoppingListRequest(
      familyId: (json['familyId'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) =>
              CreateShoppingItemRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateShoppingListRequestToJson(
        CreateShoppingListRequest instance) =>
    <String, dynamic>{
      'familyId': instance.familyId,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

CreateShoppingItemRequest _$CreateShoppingItemRequestFromJson(
        Map<String, dynamic> json) =>
    CreateShoppingItemRequest(
      masterProductId: (json['masterProductId'] as num?)?.toInt(),
      customProductName: json['customProductName'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      note: json['note'] as String?,
      assignedToId: (json['assignedToId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateShoppingItemRequestToJson(
        CreateShoppingItemRequest instance) =>
    <String, dynamic>{
      'masterProductId': instance.masterProductId,
      'customProductName': instance.customProductName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'note': instance.note,
      'assignedToId': instance.assignedToId,
    };

UpdateShoppingItemRequest _$UpdateShoppingItemRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateShoppingItemRequest(
      isBought: json['isBought'] as bool?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      note: json['note'] as String?,
      assignedToId: (json['assignedToId'] as num?)?.toInt(),
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateShoppingItemRequestToJson(
        UpdateShoppingItemRequest instance) =>
    <String, dynamic>{
      'isBought': instance.isBought,
      'quantity': instance.quantity,
      'note': instance.note,
      'assignedToId': instance.assignedToId,
      'version': instance.version,
    };
