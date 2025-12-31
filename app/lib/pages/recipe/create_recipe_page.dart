import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
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
  
  final List<String> _selectedIngredients = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    _ingredientsDisplayController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final recipeData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': null,
        'serves': 4,      
        'prepTime': 15,     
        'cookTime': 20,    
        'difficulty': Difficulty.MEDIUM.toString().split('.').last,
        'isPublic': true,
        'ingredients': _selectedIngredients,
        'steps': _stepsController.text.split('\n').where((s) => s.isNotEmpty).toList(),
        'notes': _notesController.text.split('\n').where((s) => s.isNotEmpty).toList(),
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
    // ... (This function remains the same)
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
              const Center(child: CircleAvatar(radius: 70, backgroundColor: Color(0xFFF0F0F0), child: Text('Ảnh công thức', style: TextStyle(color: Colors.grey)))),
              const SizedBox(height: 40),
              _buildTextField(label: 'Tên công thức', controller: _titleController, hint: 'Mì xào mằn mòi'),
              const SizedBox(height: 16),
              _buildTextField(label: 'Mô tả ngắn', controller: _descriptionController, hint: 'Một món ăn đơn giản, dễ làm tại nhà...'),
              const SizedBox(height: 24),
              _buildTextField(label: 'Nguyên liệu', controller: _ingredientsDisplayController, hint: 'Chạm để chọn nguyên liệu', isDropdown: true, onTap: _showIngredientSelectionDialog),
              const SizedBox(height: 24),
              _buildTextField(label: 'Các bước làm', controller: _stepsController, hint: 'Bước 1...\nBước 2...\nBước 3...', maxLines: 5),
              const SizedBox(height: 24),
              _buildTextField(label: 'Ghi chú', controller: _notesController, hint: 'Các lưu ý...', maxLines: 3),
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

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, bool isDropdown = false, int maxLines = 1, VoidCallback? onTap}) {
    // ... (This helper method remains exactly the same)
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
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down) : null,
          ),
          validator: (value) {
            if (!isDropdown && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập thông tin';
            }
            return null;
          },
        ),
      ],
    );
  }
}
