import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/providers/meal_plan_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/recipe_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/meal_plan/create_meal_plan_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  DateTime _selectedDate = DateTime.now();
  late PageController _pageController;
  int _currentPageIndex = 500;
  
  // Track the initial page index based on today's date
  static const int _basePageIndex = 500;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _basePageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;
    if (selectedFamily != null) {
      context.read<MealPlanProvider>().fetchDailyMealPlans(selectedFamily.id, _selectedDate);
    }
  }

  DateTime _getDateFromPageIndex(int index) {
    // Base date is today at page index 500
    final today = DateTime.now();
    final baseDate = DateTime(today.year, today.month, today.day);
    return baseDate.add(Duration(days: index - _basePageIndex));
  }
  
  int _getPageIndexFromDate(DateTime date) {
    final today = DateTime.now();
    final baseDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return _basePageIndex + targetDate.difference(baseDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch bữa ăn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildFamilySelector(),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: Consumer<MealPlanProvider>(
              builder: (context, provider, child) {
                if (provider.viewStatus == ViewStatus.Loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                      ],
                    ),
                  );
                }

                return PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    final newDate = _getDateFromPageIndex(index);
                    if (_currentPageIndex != index) {
                      setState(() {
                        _currentPageIndex = index;
                        _selectedDate = newDate;
                      });
                      _loadDataForDate(newDate);
                    }
                  },
                  itemBuilder: (context, index) {
                    return _buildDayView(provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealPlanDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFamilySelector() {
    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, child) {
        final families = familyProvider.families;
        final selectedFamily = familyProvider.selectedFamily;
        
        if (families.isEmpty || selectedFamily == null) {
          return const SizedBox.shrink();
        }
        
        if (families.length == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom, size: 18),
                const SizedBox(width: 4),
                Text(
                  selectedFamily.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }
        
        return PopupMenuButton<int>(
          onSelected: (familyId) {
            final family = families.firstWhere((f) => f.id == familyId);
            familyProvider.setSelectedFamily(family);
            _loadData();
          },
          itemBuilder: (context) => families.map((family) => PopupMenuItem<int>(
            value: family.id,
            child: Row(
              children: [
                if (family.id == selectedFamily.id)
                  const Icon(Icons.check, color: Colors.orange, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(family.name)),
              ],
            ),
          )).toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom, size: 18),
                const SizedBox(width: 4),
                Text(
                  selectedFamily.name,
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.orange,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              GestureDetector(
                onTap: () => _selectDate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeekDays(),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isSelected = date.day == _selectedDate.day && 
                          date.month == _selectedDate.month && 
                          date.year == _selectedDate.year;
        final isToday = date.day == DateTime.now().day && 
                       date.month == DateTime.now().month && 
                       date.year == DateTime.now().year;

        return GestureDetector(
          onTap: () {
            final newIndex = _getPageIndexFromDate(date);
            setState(() {
              _selectedDate = date;
              _currentPageIndex = newIndex;
            });
            _pageController.jumpToPage(newIndex);
            _loadDataForDate(date);
          },
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected 
                  ? Border.all(color: Colors.white, width: 2) 
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getWeekDayShort(date.weekday),
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayView(MealPlanProvider provider) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: MealType.values.map((mealType) {
          final mealPlan = provider.getMealPlanForType(mealType);
          return _buildMealCard(mealType, mealPlan, provider);
        }).toList(),
      ),
    );
  }

  Widget _buildMealCard(MealType mealType, MealPlan? mealPlan, MealPlanProvider provider) {
    final hasItems = mealPlan?.items?.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getMealTypeColor(mealType).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  mealType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mealType.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getMealTypeColor(mealType),
                      fontSize: 16,
                    ),
                  ),
                ),
                if (mealPlan != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: _getMealTypeColor(mealType),
                    onPressed: () => _showAddMealItemDialog(mealPlan.id),
                  ),
              ],
            ),
          ),
          if (!hasItems)
            InkWell(
              onTap: () => _navigateToCreateMealPlan(mealType),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.add_circle_outline, size: 32, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm món cho ${mealType.displayName.toLowerCase()}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: mealPlan!.items!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = mealPlan.items![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getMealTypeColor(mealType).withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: _getMealTypeColor(mealType)),
                    ),
                  ),
                  title: Text(item.displayName),
                  subtitle: Text('${item.servings} phần'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteMealItem(item, mealPlan.id, provider),
                  ),
                  onTap: () => _showRecipeDetails(item),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddMealPlanDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn bữa ăn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...MealType.values.map((type) => ListTile(
              leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateMealPlan(type);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateMealPlan(MealType mealType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateMealPlanPage(
          date: _selectedDate,
          mealType: mealType,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _showAddMealItemDialog(int mealPlanId) {
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
              'Thêm món ăn',
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
                final item = CreateMealItemRequest(
                  customDishName: name,
                  servings: int.tryParse(servingsController.text) ?? 2,
                );
                context.read<MealPlanProvider>().addMealItem(mealPlanId, item);
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

  void _showRecipeDetails(MealItem item) async {
    final recipe = item.recipe;
    
    if (recipe == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Món ăn này chưa có công thức'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch recipe details
    try {
      await context.read<RecipeProvider>().fetchRecipeById(recipe.id);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final recipeDetail = context.read<RecipeProvider>().selectedRecipeDetail;
      if (recipeDetail == null) {
        _showErrorDialog('Không thể tải thông tin công thức');
        return;
      }

      _showRecipeDetailDialog(item, recipeDetail);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Lỗi: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetailDialog(MealItem item, RecipeDetail recipeDetail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, size: 28, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recipeDetail.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.people, '${item.servings} phần', Colors.orange),
                  if (recipeDetail.prepTime != null && recipeDetail.prepTime! > 0)
                    _buildInfoChip(Icons.schedule, '${recipeDetail.prepTime} phút chuẩn bị', Colors.blue),
                  if (recipeDetail.cookTime != null && recipeDetail.cookTime! > 0)
                    _buildInfoChip(Icons.timer, '${recipeDetail.cookTime} phút nấu', Colors.green),
                  _buildInfoChip(
                    Icons.star,
                    recipeDetail.difficulty == Difficulty.EASY
                        ? 'Dễ'
                        : recipeDetail.difficulty == Difficulty.MEDIUM
                            ? 'Trung bình'
                            : 'Khó',
                    Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (recipeDetail.description.isNotEmpty) ...[
                      const Text(
                        'Mô tả',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipeDetail.description,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (recipeDetail.ingredients.isNotEmpty) ...[
                      const Text(
                        'Nguyên liệu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...recipeDetail.ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${ingredient.customIngredientName ?? ingredient.ingredientName} - ${ingredient.quantity} ${ingredient.unit}${ingredient.note != null ? " (${ingredient.note})" : ""}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                    if (recipeDetail.instructions != null && recipeDetail.instructions!.isNotEmpty) ...[
                      const Text(
                        'Cách làm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...recipeDetail.steps!.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 15, height: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    if (recipeDetail.notes != null && recipeDetail.notes!.isNotEmpty) ...[
                      const Text(
                        'Ghi chú',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recipeDetail.notes!,
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMealItem(MealItem item, int mealPlanId, MealPlanProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${item.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMealItem(item.id, mealPlanId);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final newIndex = _getPageIndexFromDate(picked);
      setState(() {
        _selectedDate = picked;
        _currentPageIndex = newIndex;
      });
      _pageController.jumpToPage(newIndex);
      _loadDataForDate(picked);
    }
  }

  void _loadDataForDate(DateTime date) {
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;
    if (selectedFamily != null) {
      context.read<MealPlanProvider>().fetchDailyMealPlans(selectedFamily.id, date);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
      return 'Hôm qua';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.day == tomorrow.day && date.month == tomorrow.month && date.year == tomorrow.year) {
      return 'Ngày mai';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getWeekDayShort(int weekday) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[weekday - 1];
  }

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.BREAKFAST:
        return Colors.amber;
      case MealType.LUNCH:
        return Colors.orange;
      case MealType.DINNER:
        return Colors.deepOrange;
      case MealType.SNACK:
        return Colors.brown;
    }
  }
}
