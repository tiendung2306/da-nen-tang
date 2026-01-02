import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/product_provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'ai_recipe_suggestion_dialog.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({Key? key}) : super(key: key);

  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _notesController = TextEditingController();
  final _ingredientsDisplayController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _prepTimeController = TextEditingController(text: '15');
  final _cookTimeController = TextEditingController(text: '20');
  
  final List<Map<String, dynamic>> _selectedIngredients = [];
  Difficulty _selectedDifficulty = Difficulty.MEDIUM;
  bool _isLoading = false;
  
  void _updateIngredientsDisplay() {
    if (_selectedIngredients.isEmpty) {
      _ingredientsDisplayController.text = '';
      return;
    }
    final display = _selectedIngredients.map((ing) {
      final name = ing['name'];
      final quantity = ing['quantity'] ?? 1;
      final unit = ing['unit'] ?? 'phần';
      return '$name ($quantity $unit)';
    }).join(', ');
    _ingredientsDisplayController.text = display;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    _ingredientsDisplayController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final recipeData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': null,
        'servings': int.tryParse(_servingsController.text) ?? 4,
        'prepTime': int.tryParse(_prepTimeController.text) ?? 15,
        'cookTime': int.tryParse(_cookTimeController.text) ?? 20,
        'difficulty': _selectedDifficulty.toString().split('.').last,
        'isPublic': true,
        'instructions': _stepsController.text,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'ingredients': _selectedIngredients.map((ing) => {
          'masterProductId': ing['id'] is int ? ing['id'] : null,
          'customIngredientName': ing['name'],
          'quantity': ing['quantity'] ?? 1.0,
          'unit': ing['unit'] ?? 'phần',
          'note': ing['note'],
          'isOptional': ing['isOptional'] ?? false,
        }).toList(),
      };

      try {
        await context.read<RecipeProvider>().createRecipe(recipeData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo công thức thành công!'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } catch (e) {
         if (mounted) {
          // FIX: Show a more specific error message from the API
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $errorMessage'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showAISuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<FridgeProvider>()),
          ChangeNotifierProvider.value(value: context.read<FamilyProvider>()),
        ],
        child: AIRecipeSuggestionDialog(
          onRecipeSelected: _applyAISuggestedRecipe,
        ),
      ),
    );
  }

  void _applyAISuggestedRecipe(Map<String, dynamic> recipe) {
    setState(() {
      // Fill in the form fields
      _titleController.text = recipe['title'] ?? '';
      _descriptionController.text = recipe['description'] ?? '';
      
      // Convert instructions array to numbered string
      final instructions = recipe['instructions'] as List<dynamic>? ?? [];
      _stepsController.text = instructions.asMap().entries.map((entry) {
        return '${entry.key + 1}. ${entry.value}';
      }).join('\n');
      
      _notesController.text = recipe['notes'] ?? '';
      
      // Parse servings, prepTime, cookTime
      if (recipe['servings'] != null) {
        _servingsController.text = recipe['servings'].toString();
      }
      if (recipe['prepTime'] != null) {
        _prepTimeController.text = recipe['prepTime'].toString();
      }
      if (recipe['cookTime'] != null) {
        _cookTimeController.text = recipe['cookTime'].toString();
      }

      // Set difficulty
      final difficultyStr = (recipe['difficulty'] ?? 'MEDIUM').toString().toUpperCase();
      if (difficultyStr == 'EASY') {
        _selectedDifficulty = Difficulty.EASY;
      } else if (difficultyStr == 'HARD') {
        _selectedDifficulty = Difficulty.HARD;
      } else {
        _selectedDifficulty = Difficulty.MEDIUM;
      }

      // Add ingredients
      _selectedIngredients.clear();
      final ingredients = recipe['ingredients'] as List?;
      if (ingredients != null) {
        for (var ing in ingredients) {
          _selectedIngredients.add({
            'id': null, // Custom ingredient, no product ID
            'name': ing['name'],
            'quantity': ing['quantity'] ?? 1.0,
            'unit': ing['unit'] ?? 'phần',
            'note': ing['note'],
            'isOptional': ing['isOptional'] ?? false,
          });
        }
      }
      _updateIngredientsDisplay();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã áp dụng công thức từ AI. Bạn có thể chỉnh sửa trước khi lưu.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showIngredientSelectionDialog() {
    // Load products immediately when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
    
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chọn nguyên liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Search and add custom ingredient
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm hoặc nhập nguyên liệu mới...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              context.read<ProductProvider>().fetchProducts();
                            } else {
                              context.read<ProductProvider>().searchProducts(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFF26F21), size: 32),
                        tooltip: 'Thêm nguyên liệu tùy chỉnh',
                        onPressed: () {
                          final customName = searchController.text.trim();
                          if (customName.isNotEmpty) {
                            _showAddIngredientDetailDialog(
                              customName, 
                              null, // No product ID for custom
                              (ingredient) {
                                setState(() {
                                  _selectedIngredients.add(ingredient);
                                });
                                this.setState(() => _updateIngredientsDisplay());
                                searchController.clear();
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập tên nguyên liệu')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Selected ingredients list
                  if (_selectedIngredients.isNotEmpty) ...[
                    const Text('Đã chọn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _selectedIngredients.length,
                        itemBuilder: (context, index) {
                          final ing = _selectedIngredients[index];
                          final hasDetails = ing['quantity'] != null || ing['note'] != null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              title: Text(ing['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: hasDetails 
                                ? Text('${ing['quantity'] ?? 1} ${ing['unit'] ?? 'phần'}${ing['note'] != null ? ' - ${ing['note']}' : ''}')
                                : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditIngredientDialog(index, ing, (updated) {
                                      setState(() {
                                        _selectedIngredients[index] = updated;
                                      });
                                      this.setState(() => _updateIngredientsDisplay());
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _selectedIngredients.removeAt(index);
                                      });
                                      this.setState(() => _updateIngredientsDisplay());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                  const SizedBox(height: 8),
                  const Text('Nguyên liệu có sẵn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, child) {
                        if (provider.viewStatus == ViewStatus.Loading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                const Text('Không tìm thấy nguyên liệu'),
                                const SizedBox(height: 4),
                                Text(
                                  'Nhấn nút + để thêm nguyên liệu tùy chỉnh',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: provider.products.length,
                          itemBuilder: (context, index) {
                            final product = provider.products[index];
                            final isSelected = _selectedIngredients.any((ing) => ing['id'] == product.id);
                            final categoryName = product.categories?.isNotEmpty == true ? product.categories!.first.name : 'Chưa phân loại';
                            return ListTile(
                              dense: true,
                              title: Text(product.name),
                              subtitle: Text('$categoryName - ${product.defaultUnit}'),
                              trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: Color(0xFFF26F21))
                                : IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF26F21)),
                                    onPressed: () {
                                      _showAddIngredientDetailDialog(
                                        product.name, 
                                        product.id,
                                        (ingredient) {
                                          setState(() {
                                            _selectedIngredients.add(ingredient);
                                          });
                                          this.setState(() => _updateIngredientsDisplay());
                                        },
                                        defaultUnit: product.defaultUnit,
                                      );
                                    },
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Tổng: ${_selectedIngredients.length} nguyên liệu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                    child: const Text('Xong', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddIngredientDetailDialog(String name, int? productId, Function(Map<String, dynamic>) onAdd, {String? defaultUnit}) {
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: defaultUnit ?? 'phần');
    final noteController = TextEditingController();
    bool isOptional = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm: $name'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Số lượng',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị',
                          border: OutlineInputBorder(),
                          hintText: 'g, ml, thìa, quả...',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                    hintText: 'VD: thái nhỏ, băm nhuyễn...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Tùy chọn (không bắt buộc)'),
                  value: isOptional,
                  onChanged: (value) => setState(() => isOptional = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = double.tryParse(quantityController.text) ?? 1.0;
                final unit = unitController.text.trim();
                if (unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đơn vị')),
                  );
                  return;
                }
                onAdd({
                  'id': productId,
                  'name': name,
                  'quantity': quantity,
                  'unit': unit,
                  'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  'isOptional': isOptional,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditIngredientDialog(int index, Map<String, dynamic> ingredient, Function(Map<String, dynamic>) onUpdate) {
    final quantityController = TextEditingController(text: (ingredient['quantity'] ?? 1).toString());
    final unitController = TextEditingController(text: ingredient['unit'] ?? 'phần');
    final noteController = TextEditingController(text: ingredient['note'] ?? '');
    bool isOptional = ingredient['isOptional'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Sửa: ${ingredient['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Số lượng',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                    hintText: 'VD: thái nhỏ, băm nhuyễn...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Tùy chọn (không bắt buộc)'),
                  value: isOptional,
                  onChanged: (value) => setState(() => isOptional = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = double.tryParse(quantityController.text) ?? 1.0;
                final unit = unitController.text.trim();
                if (unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đơn vị')),
                  );
                  return;
                }
                onUpdate({
                  'id': ingredient['id'],
                  'name': ingredient['name'],
                  'quantity': quantity,
                  'unit': unit,
                  'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  'isOptional': isOptional,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (The entire build method remains exactly the same)
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFF26F21)),
            tooltip: 'Đề xuất công thức từ AI',
            onPressed: _showAISuggestionDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(child: CircleAvatar(radius: 70, backgroundColor: Color(0xFFF0F0F0), child: Icon(Icons.restaurant, size: 50, color: Colors.grey))),
              const SizedBox(height: 40),
              _buildTextField(label: 'Tên công thức *', controller: _titleController, hint: 'Mì xào mằn mòi'),
              const SizedBox(height: 16),
              _buildTextField(label: 'Mô tả ngắn *', controller: _descriptionController, hint: 'Một món ăn đơn giản, dễ làm tại nhà...'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Độ khó *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Difficulty>(
                          value: _selectedDifficulty,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          items: const [
                            DropdownMenuItem(value: Difficulty.EASY, child: Text('🟢 Dễ')),
                            DropdownMenuItem(value: Difficulty.MEDIUM, child: Text('🟡 Trung bình')),
                            DropdownMenuItem(value: Difficulty.HARD, child: Text('🔴 Khó')),
                          ],
                          onChanged: (value) => setState(() => _selectedDifficulty = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(label: 'Số phần', controller: _servingsController, hint: '4', keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: 'Chuẩn bị (phút)', controller: _prepTimeController, hint: '15', keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(label: 'Nấu (phút)', controller: _cookTimeController, hint: '20', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(label: 'Nguyên liệu', controller: _ingredientsDisplayController, hint: 'Chạm để chọn nguyên liệu', isDropdown: true, onTap: _showIngredientSelectionDialog),
              const SizedBox(height: 24),
              _buildTextField(label: 'Các bước làm *', controller: _stepsController, hint: 'Bước 1: ...\nBước 2: ...\nBước 3: ...', maxLines: 5),
              const SizedBox(height: 24),
              _buildTextField(label: 'Ghi chú', controller: _notesController, hint: 'Món ăn sẽ có vị chua nhẹ, Ngon hơn khi uống lạnh...', maxLines: 3, required: false),
              const SizedBox(height: 48),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy bỏ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveRecipe, child: const Text('Lưu công thức', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: orangeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    required String hint, 
    bool isDropdown = false, 
    int maxLines = 1, 
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: onTap != null,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down) : null,
          ),
          validator: (value) {
            if (required && !isDropdown && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập thông tin';
            }
            return null;
          },
        ),
      ],
    );
  }
}
