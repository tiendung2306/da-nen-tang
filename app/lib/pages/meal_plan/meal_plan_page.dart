import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/providers/meal_plan_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/meal_plan/create_meal_plan_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController(initialPage: 500);
  int _currentPageIndex = 500;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    return DateTime.now().add(Duration(days: index - 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch bữa ăn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    setState(() {
                      _currentPageIndex = index;
                      _selectedDate = _getDateFromPageIndex(index);
                    });
                    _loadDataForDate(_selectedDate);
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
        onPressed: () => _showActionMenu(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            setState(() {
              _selectedDate = date;
            });
            final newIndex = 500 + date.difference(DateTime.now()).inDays;
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
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: _getMealTypeColor(mealType)),
                    onSelected: (value) {
                      switch (value) {
                        case 'copy':
                          _showCopyMealPlanDialog(mealPlan);
                          break;
                        case 'delete':
                          _confirmDeleteMealPlan(mealPlan, provider);
                          break;
                        case 'edit_note':
                          _showEditNoteDialog(mealPlan);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18),
                            SizedBox(width: 8),
                            Text('Sao chép'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_note',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note, size: 18),
                            SizedBox(width: 8),
                            Text('Sửa ghi chú'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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

  void _showEditMealItemDialog(MealItem item, int mealPlanId) {
    final nameController = TextEditingController(text: item.customDishName ?? item.recipeName);
    final servingsController = TextEditingController(text: item.servings.toString());
    final noteController = TextEditingController(text: item.note);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa món ăn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
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
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên món')),
                );
                return;
              }
              final updatedItem = CreateMealItemRequest(
                customDishName: name,
                servings: int.tryParse(servingsController.text) ?? 2,
                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              );
              context.read<MealPlanProvider>().updateMealItem(item.id, mealPlanId, updatedItem);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCopyMealPlanDialog(MealPlan mealPlan) {
    DateTime? selectedDate;
    MealType? selectedMealType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sao chép thực đơn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ngày'),
                subtitle: Text(selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'Chọn ngày'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              DropdownButtonFormField<MealType>(
                value: selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Bữa ăn (không bắt buộc)',
                  border: OutlineInputBorder(),
                ),
                items: MealType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type.icon} ${type.displayName}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedMealType = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedDate == null
                  ? null
                  : () async {
                      final result = await context.read<MealPlanProvider>().copyMealPlan(
                        mealPlan.id,
                        targetDate: selectedDate!,
                        targetMealType: selectedMealType,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        if (result != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sao chép thành công!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sao chép thất bại!'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Sao chép', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(MealPlan mealPlan) {
    final noteController = TextEditingController(text: mealPlan.note);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa ghi chú'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MealPlanProvider>().updateMealPlan(
                mealPlan.id,
                note: noteController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMealPlan(MealPlan mealPlan, MealPlanProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thực đơn "${mealPlan.mealType.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final success = await provider.deleteMealPlan(mealPlan.id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa thành công!')),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.orange),
              title: const Text('Thêm thực đơn mới'),
              onTap: () {
                Navigator.pop(context);
                _showAddMealPlanDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('Tạo danh sách mua sắm'),
              subtitle: const Text('Từ thực đơn trong tuần'),
              onTap: () {
                Navigator.pop(context);
                _showGenerateShoppingListDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateShoppingListDialog() {
    DateTime startDate = _selectedDate;
    DateTime endDate = _selectedDate.add(const Duration(days: 6));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo danh sách mua sắm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Từ ngày'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('Đến ngày'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final familyProvider = context.read<FamilyProvider>();
                final selectedFamily = familyProvider.selectedFamily;
                if (selectedFamily == null) return;

                final result = await context.read<MealPlanProvider>().generateShoppingListFromMealPlans(
                  selectedFamily.id,
                  startDate: startDate,
                  endDate: endDate,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  if (result != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Thành công!'),
                        content: const Text('Danh sách mua sắm đã được tạo. Bạn có thể xem trong trang "Danh sách mua sắm".'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo danh sách thất bại!'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Tạo danh sách', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
      setState(() {
        _selectedDate = picked;
      });
      final newIndex = 500 + picked.difference(DateTime.now()).inDays;
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
