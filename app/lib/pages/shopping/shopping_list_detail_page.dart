import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';

class ShoppingListDetailPage extends StatefulWidget {
  final int shoppingListId;

  const ShoppingListDetailPage({Key? key, required this.shoppingListId}) : super(key: key);

  @override
  State<ShoppingListDetailPage> createState() => _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState extends State<ShoppingListDetailPage> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<ShoppingListProvider>().fetchShoppingListDetails(widget.shoppingListId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, child) {
        final shoppingList = provider.currentShoppingList;

        return Scaffold(
          appBar: AppBar(
            title: Text(shoppingList?.name ?? 'Chi tiết danh sách'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              if (shoppingList != null)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, provider, shoppingList),
                  itemBuilder: (context) => [
                    if (shoppingList.status == ShoppingListStatus.DRAFT)
                      const PopupMenuItem(value: 'start', child: Text('Bắt đầu mua sắm')),
                    if (shoppingList.status == ShoppingListStatus.SHOPPING)
                      const PopupMenuItem(value: 'complete', child: Text('Hoàn thành')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa danh sách', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          body: _buildBody(provider, shoppingList),
          floatingActionButton: shoppingList != null && shoppingList.status != ShoppingListStatus.COMPLETED
              ? FloatingActionButton(
                  onPressed: () => _showAddItemDialog(),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(ShoppingListProvider provider, ShoppingList? shoppingList) {
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

    if (shoppingList == null) {
      return const Center(child: Text('Không tìm thấy danh sách'));
    }

    final items = shoppingList.items ?? [];
    final unboughtItems = items.where((item) => !item.isBought).toList();
    final boughtItems = items.where((item) => item.isBought).toList();

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ: ${shoppingList.boughtItems}/${shoppingList.totalItems}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: shoppingList.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(shoppingList.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStatusText(shoppingList.status),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Items list
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có món nào trong danh sách'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (unboughtItems.isNotEmpty) ...[
                      Text(
                        'Cần mua (${unboughtItems.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...unboughtItems.map((item) => _buildItemCard(item, provider)),
                    ],
                    if (boughtItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Đã mua (${boughtItems.length})',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ...boughtItems.map((item) => _buildItemCard(item, provider)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ShoppingItem item, ShoppingListProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isBought,
          onChanged: provider.currentShoppingList?.status == ShoppingListStatus.COMPLETED
              ? null
              : (value) {
                  provider.toggleItemBought(item.id, value ?? false, version: item.version);
                },
          activeColor: Colors.green,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isBought ? TextDecoration.lineThrough : null,
            color: item.isBought ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${item.quantity} ${item.unit ?? ''}'.trim(),
          style: TextStyle(color: item.isBought ? Colors.grey : Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDeleteItem(item, provider),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _itemNameController.clear();
    _quantityController.text = '1';
    _unitController.clear();

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
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Tên món *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_basket),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
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
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị (kg, lít, cái...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Thêm món', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final name = _itemNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên món')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 1;
    final unit = _unitController.text.trim();

    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đơn vị (vd: kg, quả, gói...)')),
      );
      return;
    }

    final item = CreateShoppingItemRequest(
      customProductName: name,
      quantity: quantity,
      unit: unit,
    );

    context.read<ShoppingListProvider>().addShoppingItem(widget.shoppingListId, item);
    Navigator.pop(context);
  }

  void _confirmDeleteItem(ShoppingItem item, ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteShoppingItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, ShoppingListProvider provider, ShoppingList list) {
    switch (action) {
      case 'start':
        provider.updateShoppingListStatus(list.id, ShoppingListStatus.SHOPPING, version: list.version ?? 0);
        break;
      case 'complete':
        provider.updateShoppingListStatus(list.id, ShoppingListStatus.COMPLETED, version: list.version ?? 0);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa danh sách này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await provider.deleteShoppingList(list.id);
                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;
    }
  }

  Color _getStatusColor(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.DRAFT:
        return Colors.orange;
      case ShoppingListStatus.SHOPPING:
        return Colors.blue;
      case ShoppingListStatus.COMPLETED:
        return Colors.green;
    }
  }

  String _getStatusText(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.DRAFT:
        return 'Đang lập';
      case ShoppingListStatus.SHOPPING:
        return 'Đang mua';
      case ShoppingListStatus.COMPLETED:
        return 'Hoàn thành';
    }
  }
}
