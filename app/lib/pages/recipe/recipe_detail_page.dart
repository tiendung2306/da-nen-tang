import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().fetchRecipeById(widget.recipe.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.userInfo;
              final isOwner = currentUser != null && currentUser.id == widget.recipe.createdBy.id;
              
              if (!isOwner) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Xóa công thức', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          final recipeDetail = recipeProvider.selectedRecipeDetail;

          if (recipeProvider.viewStatus == ViewStatus.Loading && recipeDetail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use detail if available, otherwise fall back to basic recipe
          if (recipeDetail == null) {
            return const Center(child: Text('Không thể tải chi tiết công thức'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: recipeDetail.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            recipeDetail.imageUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 24),
                Center(child: Text(recipeDetail.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24), textAlign: TextAlign.center)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'bởi ${recipeDetail.createdBy.fullName ?? recipeDetail.createdBy.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                if (recipeDetail.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      recipeDetail.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoCard(Icons.people, 'Phần ăn', '${recipeDetail.serves ?? 0}'),
                    _buildInfoCard(Icons.schedule, 'Chuẩn bị', '${recipeDetail.prepTime ?? 0} ph'),
                    _buildInfoCard(Icons.timer, 'Nấu', '${recipeDetail.cookTime ?? 0} ph'),
                    _buildDifficultyCard(recipeDetail.difficulty),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Danh sách nguyên liệu', Icons.shopping_basket),
                const SizedBox(height: 8),
                _buildIngredientsList(recipeDetail.ingredients),
                const Divider(height: 40, thickness: 1),
                _buildSectionTitle('Cách làm', Icons.format_list_numbered),
                const SizedBox(height: 8),
                if (recipeDetail.steps != null && recipeDetail.steps!.isNotEmpty)
                  _buildBulletList(recipeDetail.steps!, isNumbered: true)
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text('Chưa có hướng dẫn', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF26F21), size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildIngredientsList(List<RecipeIngredient> ingredients) {
    if (ingredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Text('Chưa có nguyên liệu', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ingredients.map((ingredient) {
          final name = ingredient.customIngredientName ?? ingredient.ingredientName;
          final quantityText = '${ingredient.quantity} ${ingredient.unit}';
          final noteText = ingredient.note != null && ingredient.note!.isNotEmpty ? ' (${ingredient.note})' : '';
          final optionalText = ingredient.isOptional ? ' [Tùy chọn]' : '';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '• $name - $quantityText$noteText$optionalText',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBulletList(List<String> items, {bool isNumbered = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(isNumbered ? '${entry.key + 1}. ${entry.value}' : '• ${entry.value}', style: const TextStyle(fontSize: 16, height: 1.5)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF26F21), size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(Difficulty difficulty) {
    Color color;
    String label;
    IconData icon;
    switch (difficulty) {
      case Difficulty.EASY:
        color = Colors.green;
        label = 'Dễ';
        icon = Icons.sentiment_satisfied;
        break;
      case Difficulty.MEDIUM:
        color = Colors.orange;
        label = 'Trung bình';
        icon = Icons.sentiment_neutral;
        break;
      case Difficulty.HARD:
        color = Colors.red;
        label = 'Khó';
        icon = Icons.sentiment_very_dissatisfied;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công thức "${widget.recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await context.read<RecipeProvider>().deleteRecipe(widget.recipe.id);
                if (mounted) {
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa công thức thành công!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
