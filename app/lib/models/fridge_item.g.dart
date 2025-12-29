// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FridgeItem _$FridgeItemFromJson(Map<String, dynamic> json) => FridgeItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$FridgeItemToJson(FridgeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'expiryDate': instance.expiryDate.toIso8601String(),
      'location': instance.location,
      'imageUrl': instance.imageUrl,
    };
