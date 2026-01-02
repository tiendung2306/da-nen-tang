import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'recipe_detail_page.dart';
import 'create_recipe_page.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'latest'; // latest, title

  @override
  void initState() {
    super.initState();
    final recipeProvider = context.read<RecipeProvider>();
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Thực Đơn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
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
                                context.read<RecipeProvider>().fetchRecipes(isRefresh: true);
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
                    onSubmitted: (value) {
                      // Implement search API call here when available
                      setState(() {});
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                    // Implement sort functionality
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'latest', child: Row(children: [Icon(Icons.access_time), SizedBox(width: 8), Text('Mới nhất')])),
                    const PopupMenuItem(value: 'title', child: Row(children: [Icon(Icons.sort_by_alpha), SizedBox(width: 8), Text('Tên A-Z')])),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách thực đơn', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRecipePage()));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, child) {
                if (provider.viewStatus == ViewStatus.Loading && provider.recipes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.recipes.isEmpty) {
                  return const Center(child: Text('Không có công thức nào.'));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchRecipes(isRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8.0),
                    itemCount: provider.recipes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.recipes.length) {
                        return provider.isLoadingMore ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink();
                      }
                      final recipe = provider.recipes[index];
                      
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
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe))),
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
