import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';

class CreateShoppingListPage extends StatefulWidget {
  const CreateShoppingListPage({Key? key}) : super(key: key);

  @override
  State<CreateShoppingListPage> createState() => _CreateShoppingListPageState();
}

class _CreateShoppingListPageState extends State<CreateShoppingListPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_TempItem> _items = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo danh sách mới'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createList,
            child: const Text('Tạo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh sách *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list_alt),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên danh sách';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (không bắt buộc)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Các món cần mua',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addTempItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm món'),
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
                          Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có món nào',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn có thể thêm món sau khi tạo danh sách',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
            ),
    );
  }

  Widget _buildItemCard(int index, _TempItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Text('${index + 1}', style: const TextStyle(color: Colors.green)),
        ),
        title: Text(item.name),
        subtitle: Text('${item.quantity} ${item.unit ?? ''}'.trim()),
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

  void _addTempItem() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController();

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
              'Thêm món mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị *',
                      hintText: 'vd: kg, quả, gói...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final unit = unitController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên món')),
                  );
                  return;
                }
                if (unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đơn vị (vd: kg, quả, gói...)')),
                  );
                  return;
                }
                setState(() {
                  _items.add(_TempItem(
                    name: name,
                    quantity: double.tryParse(quantityController.text) ?? 1,
                    unit: unit,
                  ));
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) return;

    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;
    
    if (selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn gia đình trước')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ShoppingListProvider>();
    final items = _items.map((item) => CreateShoppingItemRequest(
      customProductName: item.name,
      quantity: item.quantity,
      unit: item.unit,
    )).toList();

    final result = await provider.createShoppingList(
      familyId: selectedFamily.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      items: items.isEmpty ? null : items,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo danh sách thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
      );
    }
  }
}

class _TempItem {
  final String name;
  final double quantity;
  final String unit;

  _TempItem({required this.name, required this.quantity, required this.unit});
}
