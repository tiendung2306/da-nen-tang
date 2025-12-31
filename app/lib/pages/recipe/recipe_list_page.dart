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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa tìm kiếm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30.0)), borderSide: BorderSide.none),
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
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
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: ListTile(
                          leading: recipe.imageUrl != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.network(recipe.imageUrl!, width: 56, height: 56, fit: BoxFit.cover))
                              : const CircleAvatar(backgroundColor: Color(0xFFF0F0F0), child: Icon(Icons.image_outlined, color: Colors.grey)),
                          title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('bởi ${recipe.createdBy.fullName}'),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe))),
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
}
