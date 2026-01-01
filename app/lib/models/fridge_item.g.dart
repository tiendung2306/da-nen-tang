// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddedBy _$AddedByFromJson(Map<String, dynamic> json) => AddedBy(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$AddedByToJson(AddedBy instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
    };

FridgeItem _$FridgeItemFromJson(Map<String, dynamic> json) => FridgeItem(
      id: (json['id'] as num).toInt(),
      familyId: (json['familyId'] as num).toInt(),
      productName: json['productName'] as String,
      customProductName: json['customProductName'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      location: json['location'] as String,
      note: json['note'] as String?,
      addedBy: AddedBy.fromJson(json['addedBy'] as Map<String, dynamic>),
      isExpiringSoon: json['isExpiringSoon'] as bool,
      isExpired: json['isExpired'] as bool,
      daysUntilExpiration: (json['daysUntilExpiration'] as num?)?.toInt(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FridgeItemToJson(FridgeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'productName': instance.productName,
      'customProductName': instance.customProductName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'location': instance.location,
      'note': instance.note,
      'addedBy': instance.addedBy,
      'isExpiringSoon': instance.isExpiringSoon,
      'isExpired': instance.isExpired,
      'daysUntilExpiration': instance.daysUntilExpiration,
      'categories': instance.categories,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
