// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FridgeStatistics _$FridgeStatisticsFromJson(Map<String, dynamic> json) =>
    FridgeStatistics(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      expiringSoonItems: (json['expiringSoonCount'] as num?)?.toInt() ?? 0,
      expiredItems: (json['expiredCount'] as num?)?.toInt() ?? 0,
      itemsByLocation: (json['itemsByLocation'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      itemsByCategory: (json['itemsByStatus'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$FridgeStatisticsToJson(FridgeStatistics instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'expiringSoonCount': instance.expiringSoonItems,
      'expiredCount': instance.expiredItems,
      'itemsByLocation': instance.itemsByLocation,
      'itemsByStatus': instance.itemsByCategory,
    };
