import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/providers/meal_plan_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';

class CreateMealPlanPage extends StatefulWidget {
  final DateTime date;
  final MealType mealType;

  const CreateMealPlanPage({
    Key? key,
    required this.date,
    required this.mealType,
  }) : super(key: key);

  @override
  State<CreateMealPlanPage> createState() => _CreateMealPlanPageState();
}

class _CreateMealPlanPageState extends State<CreateMealPlanPage> {
  final TextEditingController _noteController = TextEditingController();
  final List<_TempMealItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load recipes for suggestions
    context.read<RecipeProvider>().fetchRecipes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType.displayName} - ${DateFormat('dd/MM').format(widget.date)}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createMealPlan,
            child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Meal type header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(widget.mealType.icon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mealType.displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('EEEE, dd/MM/yyyy', 'vi').format(widget.date),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Note field
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Items section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Các món ăn',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAddCustomDishDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tự nhập'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showSelectRecipeDialog(),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('Công thức'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có món nào',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm món ăn bằng cách nhập tên hoặc chọn từ công thức',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildItemCard(index, item);
                  }),
              ],
            ),
    );
  }

  Widget _buildItemCard(int index, _TempMealItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isFromRecipe ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          child: Icon(
            item.isFromRecipe ? Icons.menu_book : Icons.restaurant,
            color: item.isFromRecipe ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(item.name),
        subtitle: Text('${item.servings} phần${item.isFromRecipe ? ' • Từ công thức' : ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              _items.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _showAddCustomDishDialog() {
    final nameController = TextEditingController();
    final servingsController = TextEditingController(text: '2');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thêm món tự nhập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: servingsController,
              decoration: const InputDecoration(
                labelText: 'Số phần ăn',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên món')),
                  );
                  return;
                }
                setState(() {
                  _items.add(_TempMealItem(
                    name: name,
                    servings: int.tryParse(servingsController.text) ?? 2,
                    isFromRecipe: false,
                  ));
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSelectRecipeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Consumer<RecipeProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chọn từ công thức',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: provider.recipes.isEmpty
                      ? const Center(child: Text('Chưa có công thức nào'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: provider.recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = provider.recipes[index];
                            return _buildRecipeItem(recipe);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecipeItem(Recipe recipe) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.2),
        child: const Icon(Icons.menu_book, color: Colors.green),
      ),
      title: Text(recipe.title),
      subtitle: Text(
        '${recipe.cookTime ?? 0} phút • ${recipe.difficulty}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.green),
        onPressed: () => _addRecipeToMeal(recipe),
      ),
      onTap: () => _showRecipeServingsDialog(recipe),
    );
  }

  void _showRecipeServingsDialog(Recipe recipe) {
    final servingsController = TextEditingController(text: '${recipe.serves ?? 2}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe.title),
        content: TextField(
          controller: servingsController,
          decoration: const InputDecoration(
            labelText: 'Số phần ăn',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close recipe list
              setState(() {
                _items.add(_TempMealItem(
                  name: recipe.title,
                  servings: int.tryParse(servingsController.text) ?? 2,
                  isFromRecipe: true,
                  recipeId: recipe.id,
                ));
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addRecipeToMeal(Recipe recipe) {
    Navigator.pop(context);
    setState(() {
      _items.add(_TempMealItem(
        name: recipe.title,
        servings: recipe.serves ?? 2,
        isFromRecipe: true,
        recipeId: recipe.id,
      ));
    });
  }

  Future<void> _createMealPlan() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một món')),
      );
      return;
    }

    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;

    if (selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn gia đình trước')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<MealPlanProvider>();
    final items = _items.map((item) => CreateMealItemRequest(
      recipeId: item.recipeId,
      customDishName: item.isFromRecipe ? null : item.name,
      servings: item.servings,
    )).toList();

    final result = await provider.createMealPlan(
      familyId: selectedFamily.id,
      date: widget.date,
      mealType: widget.mealType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      items: items,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo kế hoạch bữa ăn thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _TempMealItem {
  final String name;
  final int servings;
  final bool isFromRecipe;
  final int? recipeId;

  _TempMealItem({
    required this.name,
    required this.servings,
    required this.isFromRecipe,
    this.recipeId,
  });
}
