import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
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
      appBar: AppBar( /* ... */ ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          final recipeToDisplay = recipeProvider.selectedRecipe ?? widget.recipe;

          if (recipeProvider.viewStatus == ViewStatus.Loading && recipeProvider.selectedRecipe == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (Avatar)
                const SizedBox(height: 24),
                Center(child: Text(recipeToDisplay.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
                const SizedBox(height: 24),
                _buildSectionTitle('Danh sách nguyên liệu'),
                _buildBulletList(recipeToDisplay.ingredients ?? []),
                const Divider(height: 32),
                _buildSectionTitle('Cách làm'),
                _buildBulletList(recipeToDisplay.steps ?? [], isNumbered: true),
                const Divider(height: 32),
                _buildSectionTitle('Ghi chú'),
                _buildBulletList(recipeToDisplay.notes ?? []),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) { return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)); }

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
}
