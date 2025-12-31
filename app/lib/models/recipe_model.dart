import 'package:json_annotation/json_annotation.dart';

part 'recipe_model.g.dart';

@JsonEnum()
enum Difficulty { EASY, MEDIUM, HARD }

@JsonSerializable()
class UserSimpleResponse {
  final int id;
  final String username;
  final String fullName;

  const UserSimpleResponse({
    required this.id,
    required this.username,
    required this.fullName,
  });

  factory UserSimpleResponse.fromJson(Map<String, dynamic> json) => _$UserSimpleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserSimpleResponseToJson(this);
}

@JsonSerializable()
class Recipe {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  // FIX: Allow numeric fields to be nullable and provide default values.
  final int? serves;
  final int? prepTime;
  final int? cookTime;
  final Difficulty difficulty;
  final bool isPublic;
  final UserSimpleResponse createdBy;
  final String createdAt;

  final List<String>? ingredients;
  final List<String>? steps;
  final List<String>? notes;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.serves = 0,
    this.prepTime = 0,
    this.cookTime = 0,
    required this.difficulty,
    required this.isPublic,
    required this.createdBy,
    required this.createdAt,
    this.ingredients,
    this.steps,
    this.notes,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}
