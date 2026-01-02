import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'recipe_detail_page.dart';
import 'create_recipe_page.dart';

class FamilyRecipeListPage extends StatefulWidget {
  final Family family;

  const FamilyRecipeListPage({Key? key, required this.family}) : super(key: key);

  @override
  _FamilyRecipeListPageState createState() => _FamilyRecipeListPageState();
}

class _FamilyRecipeListPageState extends State<FamilyRecipeListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final recipeProvider = context.read<RecipeProvider>();
    final familyProvider = context.read<FamilyProvider>();
    
    // Load family members and recipes
    familyProvider.fetchFamilyMembers(widget.family.id);
    recipeProvider.fetchRecipes(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        recipeProvider.fetchMoreRecipes();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filterRecipesByFamily(List<Recipe> recipes, List<FamilyMember> members) {
    // Get all member IDs from the family
    final memberIds = members.map((m) => m.id).toSet();
    
    // Filter recipes created by family members
    return recipes.where((recipe) => memberIds.contains(recipe.createdBy.id)).toList();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Công thức nấu ăn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              widget.family.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khóa tìm kiếm',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Công thức từ thành viên trong nhóm',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer2<RecipeProvider, FamilyProvider>(
              builder: (context, recipeProvider, familyProvider, child) {
                if (recipeProvider.viewStatus == ViewStatus.Loading && recipeProvider.recipes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter recipes by family members
                final familyRecipes = _filterRecipesByFamily(recipeProvider.recipes, familyProvider.members);

                if (familyRecipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có công thức nào',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Các thành viên trong nhóm chưa chia sẻ công thức nào',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateRecipePage()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo công thức mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF26F21),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => recipeProvider.fetchRecipes(isRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8.0),
                    itemCount: familyRecipes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == familyRecipes.length) {
                        return recipeProvider.isLoadingMore 
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ))
                            : const SizedBox.shrink();
                      }
                      
                      final recipe = familyRecipes[index];
                      
                      // Filter by search query
                      if (_searchQuery.isNotEmpty && 
                          !recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                          !recipe.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                recipe.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.network(
                                          recipe.imageUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F0F0),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: const Icon(Icons.restaurant, color: Colors.grey, size: 32),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: const Icon(Icons.restaurant, color: Colors.grey, size: 32),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        recipe.description,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildInfoChip(Icons.person_outline, recipe.createdBy.fullName ?? recipe.createdBy.username),
                                          const SizedBox(width: 8),
                                          _buildDifficultyChip(recipe.difficulty),
                                          const Spacer(),
                                          if (recipe.prepTime != null && recipe.prepTime! > 0)
                                            _buildInfoChip(Icons.access_time, '${recipe.prepTime! + (recipe.cookTime ?? 0)} ph'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateRecipePage()),
          );
        },
        backgroundColor: const Color(0xFFF26F21),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(Difficulty difficulty) {
    Color color;
    String label;
    switch (difficulty) {
      case Difficulty.EASY:
        color = Colors.green;
        label = 'Dễ';
        break;
      case Difficulty.MEDIUM:
        color = Colors.orange;
        label = 'TB';
        break;
      case Difficulty.HARD:
        color = Colors.red;
        label = 'Khó';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
