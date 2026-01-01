// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSimpleResponse _$UserSimpleResponseFromJson(Map<String, dynamic> json) =>
    UserSimpleResponse(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$UserSimpleResponseToJson(UserSimpleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
    };

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      serves: (json['serves'] as num?)?.toInt() ?? 0,
      prepTime: (json['prepTime'] as num?)?.toInt() ?? 0,
      cookTime: (json['cookTime'] as num?)?.toInt() ?? 0,
      difficulty: $enumDecode(_$DifficultyEnumMap, json['difficulty']),
      isPublic: json['isPublic'] as bool,
      createdBy: UserSimpleResponse.fromJson(
          json['createdBy'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      instructions: json['instructions'] as String?,
    );

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'serves': instance.serves,
      'prepTime': instance.prepTime,
      'cookTime': instance.cookTime,
      'difficulty': _$DifficultyEnumMap[instance.difficulty]!,
      'isPublic': instance.isPublic,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'instructions': instance.instructions,
    };

const _$DifficultyEnumMap = {
  Difficulty.EASY: 'EASY',
  Difficulty.MEDIUM: 'MEDIUM',
  Difficulty.HARD: 'HARD',
};
