import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/product_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';

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
    final display = _selectedIngredients.map((ing) => ing['name']).join(', ');
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
        'serves': int.tryParse(_servingsController.text) ?? 4,
        'prepTime': int.tryParse(_prepTimeController.text) ?? 15,
        'cookTime': int.tryParse(_cookTimeController.text) ?? 20,
        'difficulty': _selectedDifficulty.toString().split('.').last,
        'isPublic': true,
        'instructions': _stepsController.text,  // Send as single text, not array
        'ingredients': _selectedIngredients.map((ing) => {
          'customIngredientName': ing['name'],
          'quantity': 1.0,
          'unit': 'phần',
          'isOptional': false,
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

  void _showIngredientSelectionDialog() {
    // Load products immediately when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nguyên liệu...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        context.read<ProductProvider>().fetchProducts();
                      } else {
                        context.read<ProductProvider>().searchProducts(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, child) {
                        if (provider.viewStatus == ViewStatus.Loading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.products.isEmpty) {
                          return const Center(child: Text('Không có nguyên liệu nào'));
                        }
                        return ListView.builder(
                          itemCount: provider.products.length,
                          itemBuilder: (context, index) {
                            final product = provider.products[index];
                            final isSelected = _selectedIngredients.any((ing) => ing['id'] == product.id);
                            final categoryName = product.categories?.isNotEmpty == true ? product.categories!.first.name : 'Chưa phân loại';
                            return CheckboxListTile(
                              title: Text(product.name),
                              subtitle: Text('$categoryName - ${product.defaultUnit}'),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedIngredients.add({'id': product.id, 'name': product.name});
                                  } else {
                                    _selectedIngredients.removeWhere((ing) => ing['id'] == product.id);
                                  }
                                });
                                this.setState(() => _updateIngredientsDisplay());
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Đã chọn: ${_selectedIngredients.length} nguyên liệu', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              _buildTextField(label: 'Ghi chú', controller: _notesController, hint: 'Các lưu ý (không bắt buộc)...', maxLines: 3, required: false),
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
