// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPlan _$MealPlanFromJson(Map<String, dynamic> json) => MealPlan(
      id: (json['id'] as num).toInt(),
      familyId: (json['familyId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      mealType: $enumDecode(_$MealTypeEnumMap, json['mealType'],
          unknownValue: MealType.BREAKFAST),
      note: json['note'] as String?,
      createdBy: json['createdBy'] == null
          ? null
          : UserInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MealPlanToJson(MealPlan instance) => <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'date': instance.date.toIso8601String(),
      'mealType': _$MealTypeEnumMap[instance.mealType]!,
      'note': instance.note,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'items': instance.items,
    };

const _$MealTypeEnumMap = {
  MealType.BREAKFAST: 'BREAKFAST',
  MealType.LUNCH: 'LUNCH',
  MealType.DINNER: 'DINNER',
  MealType.SNACK: 'SNACK',
};

MealItem _$MealItemFromJson(Map<String, dynamic> json) => MealItem(
      id: (json['id'] as num).toInt(),
      mealPlanId: (json['mealPlanId'] as num).toInt(),
      recipeId: (json['recipeId'] as num?)?.toInt(),
      recipeName: json['recipeName'] as String?,
      customDishName: json['customDishName'] as String?,
      servings: (json['servings'] as num).toInt(),
      note: json['note'] as String?,
      recipe: json['recipe'] == null
          ? null
          : Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MealItemToJson(MealItem instance) => <String, dynamic>{
      'id': instance.id,
      'mealPlanId': instance.mealPlanId,
      'recipeId': instance.recipeId,
      'recipeName': instance.recipeName,
      'customDishName': instance.customDishName,
      'servings': instance.servings,
      'note': instance.note,
      'recipe': instance.recipe,
    };

CreateMealPlanRequest _$CreateMealPlanRequestFromJson(
        Map<String, dynamic> json) =>
    CreateMealPlanRequest(
      familyId: (json['familyId'] as num).toInt(),
      date: json['date'] as String,
      mealType: json['mealType'] as String,
      note: json['note'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map(
              (e) => CreateMealItemRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateMealPlanRequestToJson(
        CreateMealPlanRequest instance) =>
    <String, dynamic>{
      'familyId': instance.familyId,
      'date': instance.date,
      'mealType': instance.mealType,
      'note': instance.note,
      'items': instance.items,
    };

CreateMealItemRequest _$CreateMealItemRequestFromJson(
        Map<String, dynamic> json) =>
    CreateMealItemRequest(
      recipeId: (json['recipeId'] as num?)?.toInt(),
      customDishName: json['customDishName'] as String?,
      servings: (json['servings'] as num).toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CreateMealItemRequestToJson(
        CreateMealItemRequest instance) =>
    <String, dynamic>{
      'recipeId': instance.recipeId,
      'customDishName': instance.customDishName,
      'servings': instance.servings,
      'note': instance.note,
    };

DailyMealPlans _$DailyMealPlansFromJson(Map<String, dynamic> json) =>
    DailyMealPlans(
      date: DateTime.parse(json['date'] as String),
      mealPlans: (json['mealPlans'] as List<dynamic>)
          .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DailyMealPlansToJson(DailyMealPlans instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'mealPlans': instance.mealPlans,
    };

WeeklyMealPlans _$WeeklyMealPlansFromJson(Map<String, dynamic> json) =>
    WeeklyMealPlans(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailyPlans: (json['dailyPlans'] as List<dynamic>)
          .map((e) => DailyMealPlans.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeeklyMealPlansToJson(WeeklyMealPlans instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'dailyPlans': instance.dailyPlans,
    };
