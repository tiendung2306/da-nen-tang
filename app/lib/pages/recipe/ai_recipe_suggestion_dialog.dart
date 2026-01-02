import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/services/fireworks_ai_service.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';

class AIRecipeSuggestionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onRecipeSelected;

  const AIRecipeSuggestionDialog({
    Key? key,
    required this.onRecipeSelected,
  }) : super(key: key);

  @override
  _AIRecipeSuggestionDialogState createState() => _AIRecipeSuggestionDialogState();
}

class _AIRecipeSuggestionDialogState extends State<AIRecipeSuggestionDialog> {
  final FireworksAIService _aiService = FireworksAIService();
  final _servingsController = TextEditingController(text: '4');
  final _dietaryController = TextEditingController();
  final _cuisineController = TextEditingController();
  
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedRecipe;
  String? _error;

  List<String> _selectedIngredients = [];

  @override
  void dispose() {
    _servingsController.dispose();
    _dietaryController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    if (_selectedIngredients.isEmpty) {
      setState(() {
        _error = 'Vui lòng chọn ít nhất một nguyên liệu từ tủ lạnh';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedRecipe = null;
    });

    try {
      final servings = int.tryParse(_servingsController.text);
      final recipe = await _aiService.generateRecipeSuggestion(
        availableIngredients: _selectedIngredients,
        servings: servings,
        dietaryPreference: _dietaryController.text.trim().isEmpty ? null : _dietaryController.text.trim(),
        cuisineType: _cuisineController.text.trim().isEmpty ? null : _cuisineController.text.trim(),
      );

      setState(() {
        _generatedRecipe = recipe;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFF26F21), size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Đề xuất công thức từ AI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _generatedRecipe == null
                  ? _buildInputForm()
                  : _buildRecipePreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    final fridgeProvider = Provider.of<FridgeProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final selectedFamily = familyProvider.selectedFamily;

    // Get fridge items
    final fridgeItems = selectedFamily != null ? fridgeProvider.items : <dynamic>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Select ingredients
          const Text(
            'Bước 1: Chọn nguyên liệu từ tủ lạnh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (selectedFamily == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Vui lòng chọn nhóm gia đình để xem nguyên liệu trong tủ lạnh'),
                  ),
                ],
              ),
            )
          else if (fridgeItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Tủ lạnh chưa có nguyên liệu nào'),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fridgeItems.length,
                itemBuilder: (context, index) {
                  final item = fridgeItems[index];
                  final ingredientName = item.customProductName ?? item.productName;
                  final isSelected = _selectedIngredients.contains(ingredientName);

                  return CheckboxListTile(
                    dense: true,
                    title: Text(ingredientName),
                    subtitle: Text('${item.quantity} ${item.unit}'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIngredients.add(ingredientName);
                        } else {
                          _selectedIngredients.remove(ingredientName);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Step 2: Additional preferences
          const Text(
            'Bước 2: Tùy chọn thêm (không bắt buộc)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _servingsController,
            decoration: const InputDecoration(
              labelText: 'Số người ăn',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cuisineController,
            decoration: const InputDecoration(
              labelText: 'Loại ẩm thực (VD: Việt Nam, Nhật Bản, Ý...)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dietaryController,
            decoration: const InputDecoration(
              labelText: 'Sở thích ăn uống (VD: chay, ít dầu mỡ...)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.favorite),
            ),
          ),
          const SizedBox(height: 20),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateRecipe,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Đang tạo đề xuất...' : 'Tạo đề xuất công thức'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF26F21),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipePreview() {
    if (_generatedRecipe == null) return const SizedBox.shrink();

    final recipe = _generatedRecipe!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe title and metadata
          Text(
            recipe['title'] ?? 'Công thức',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            recipe['description'] ?? '',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.people, '${recipe['servings'] ?? 4} người'),
              _buildInfoChip(Icons.access_time, '${(recipe['prepTime'] ?? 0) + (recipe['cookTime'] ?? 0)} phút'),
              _buildDifficultyChip(recipe['difficulty'] ?? 'MEDIUM'),
            ],
          ),
          const Divider(height: 24),

          // Ingredients
          const Text(
            'Nguyên liệu:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...((recipe['ingredients'] as List?) ?? []).map((ing) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ing['name']} - ${ing['quantity']} ${ing['unit']}${ing['isOptional'] == true ? ' (tùy chọn)' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),

          // Instructions
          const Text(
            'Cách làm:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(recipe['instructions'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          if (recipe['notes'] != null && (recipe['notes'] as String).isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Ghi chú:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recipe['notes'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _generatedRecipe = null;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tạo lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF26F21),
                    side: const BorderSide(color: Color(0xFFF26F21)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onRecipeSelected(_generatedRecipe!);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Sử dụng công thức này'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    String label;
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        color = Colors.green;
        label = 'Dễ';
        break;
      case 'HARD':
        color = Colors.red;
        label = 'Khó';
        break;
      case 'MEDIUM':
      default:
        color = Colors.orange;
        label = 'Trung bình';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
