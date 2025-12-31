import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';

part 'meal_plan_model.g.dart';

enum MealType { BREAKFAST, LUNCH, DINNER, SNACK }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.BREAKFAST:
        return 'Bữa sáng';
      case MealType.LUNCH:
        return 'Bữa trưa';
      case MealType.DINNER:
        return 'Bữa tối';
      case MealType.SNACK:
        return 'Bữa phụ';
    }
  }

  String get icon {
    switch (this) {
      case MealType.BREAKFAST:
        return '🌅';
      case MealType.LUNCH:
        return '☀️';
      case MealType.DINNER:
        return '🌙';
      case MealType.SNACK:
        return '🍪';
    }
  }
}

@JsonSerializable()
class MealPlan {
  final int id;
  final int familyId;
  final DateTime date;
  @JsonKey(unknownEnumValue: MealType.BREAKFAST)
  final MealType mealType;
  final String? note;
  final UserInfo? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MealItem>? items;

  MealPlan({
    required this.id,
    required this.familyId,
    required this.date,
    required this.mealType,
    this.note,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => _$MealPlanFromJson(json);
  Map<String, dynamic> toJson() => _$MealPlanToJson(this);
}

@JsonSerializable()
class MealItem {
  final int id;
  final int mealPlanId;
  final int? recipeId;
  final String? recipeName;
  final String? customDishName;
  final int servings;
  final String? note;
  final Recipe? recipe;

  String get displayName => customDishName ?? recipeName ?? 'Món ăn không tên';

  MealItem({
    required this.id,
    required this.mealPlanId,
    this.recipeId,
    this.recipeName,
    this.customDishName,
    required this.servings,
    this.note,
    this.recipe,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
  Map<String, dynamic> toJson() => _$MealItemToJson(this);
}

@JsonSerializable()
class CreateMealPlanRequest {
  final int familyId;
  final String date;
  final String mealType;
  final String? note;
  final List<CreateMealItemRequest>? items;

  CreateMealPlanRequest({
    required this.familyId,
    required this.date,
    required this.mealType,
    this.note,
    this.items,
  });

  factory CreateMealPlanRequest.fromJson(Map<String, dynamic> json) => _$CreateMealPlanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateMealPlanRequestToJson(this);
}

@JsonSerializable()
class CreateMealItemRequest {
  final int? recipeId;
  final String? customDishName;
  final int servings;
  final String? note;

  CreateMealItemRequest({
    this.recipeId,
    this.customDishName,
    required this.servings,
    this.note,
  });

  factory CreateMealItemRequest.fromJson(Map<String, dynamic> json) => _$CreateMealItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateMealItemRequestToJson(this);
}

@JsonSerializable()
class DailyMealPlans {
  final DateTime date;
  final List<MealPlan> mealPlans;

  DailyMealPlans({
    required this.date,
    required this.mealPlans,
  });

  MealPlan? getMealPlanByType(MealType type) {
    try {
      return mealPlans.firstWhere((plan) => plan.mealType == type);
    } catch (e) {
      return null;
    }
  }

  factory DailyMealPlans.fromJson(Map<String, dynamic> json) => _$DailyMealPlansFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMealPlansToJson(this);
}

@JsonSerializable()
class WeeklyMealPlans {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyMealPlans> dailyPlans;

  WeeklyMealPlans({
    required this.startDate,
    required this.endDate,
    required this.dailyPlans,
  });

  factory WeeklyMealPlans.fromJson(Map<String, dynamic> json) => _$WeeklyMealPlansFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyMealPlansToJson(this);
}
