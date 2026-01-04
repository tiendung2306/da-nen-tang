import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/models/product_model.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/providers/product_provider.dart';
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
  bool _selectionMode = false;
  final Set<int> _selectedItems = {};
  List<Category> _availableCategories = [];
  List<Product> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProductsAndCategories();
  }

  Future<void> _loadProductsAndCategories() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.fetchProducts(page: 0, size: 1000);
    
    setState(() {
      _availableProducts = productProvider.products;
      
      // Extract unique categories from products
      final categoryMap = <int, Category>{};
      for (var product in _availableProducts) {
        if (product.categories != null) {
          for (var category in product.categories!) {
            categoryMap[category.id] = category;
          }
        }
      }
      _availableCategories = categoryMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
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
            title: Text(_selectionMode 
                ? '${_selectedItems.length} đã chọn' 
                : shoppingList?.name ?? 'Chi tiết danh sách'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            leading: _selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectionMode = false;
                        _selectedItems.clear();
                      });
                    },
                  )
                : null,
            actions: [
              if (_selectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Chọn tất cả',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleBulkAction(value, provider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'mark_bought', child: Text('Đánh dấu đã mua')),
                    const PopupMenuItem(value: 'mark_unbought', child: Text('Đánh dấu chưa mua')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ] else if (shoppingList != null) ...[
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () {
                    setState(() {
                      _selectionMode = true;
                    });
                  },
                  tooltip: 'Chọn nhiều',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, provider, shoppingList),
                  itemBuilder: (context) => [
                    if (shoppingList.status == ShoppingListStatus.PLANNING)
                      const PopupMenuItem(value: 'start', child: Text('Bắt đầu mua sắm')),
                    if (shoppingList.status == ShoppingListStatus.SHOPPING)
                      const PopupMenuItem(value: 'complete', child: Text('Hoàn thành')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa danh sách', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ],
          ),
          body: _buildBody(provider, shoppingList),
          floatingActionButton: shoppingList != null && shoppingList.status != ShoppingListStatus.COMPLETED
              ? FloatingActionButton(
                  onPressed: () => _showAddItemDialog(),
                  backgroundColor: Colors.orange,
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
    final isSelected = _selectedItems.contains(item.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.green.withOpacity(0.1) : null,
      child: ListTile(
        onTap: _selectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove(item.id);
                  } else {
                    _selectedItems.add(item.id);
                  }
                });
              }
            : null,
        onLongPress: () {
          if (!_selectionMode) {
            setState(() {
              _selectionMode = true;
              _selectedItems.add(item.id);
            });
          }
        },
        leading: _selectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedItems.add(item.id);
                    } else {
                      _selectedItems.remove(item.id);
                    }
                  });
                },
                activeColor: Colors.green,
              )
            : Checkbox(
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
        trailing: _selectionMode
            ? null
            : IconButton(
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
    Category? selectedCategory;
    Product? selectedProduct;
    bool isCustomProduct = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<Product> getFilteredProducts() {
            if (selectedCategory == null) {
              return _availableProducts;
            }
            return _availableProducts.where((product) {
              return product.categories?.any((cat) => cat.id == selectedCategory!.id) ?? false;
            }).toList();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thêm món mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Chọn danh mục
                  DropdownButtonFormField<Category>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục (tùy chọn)',
                      border: OutlineInputBorder(),
                      helperText: 'Chọn danh mục để lọc món',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      const DropdownMenuItem<Category>(
                        value: null,
                        child: Text('Tất cả danh mục'),
                      ),
                      ..._availableCategories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategory = value;
                        selectedProduct = null;
                        isCustomProduct = true;
                        _itemNameController.clear();
                        _unitController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Chọn món có sẵn hoặc "Khác"
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Chọn món',
                      border: OutlineInputBorder(),
                      helperText: 'Chọn từ danh sách hoặc "Khác" để nhập tên riêng',
                      prefixIcon: Icon(Icons.shopping_basket),
                    ),
                    items: [
                      const DropdownMenuItem<Product>(
                        value: null,
                        child: Text('➕ Khác (nhập tên riêng)'),
                      ),
                      ...getFilteredProducts().map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text(product.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedProduct = value;
                        if (value != null) {
                          isCustomProduct = false;
                          _itemNameController.text = value.name;
                          _unitController.text = value.defaultUnit;
                        } else {
                          isCustomProduct = true;
                          _itemNameController.clear();
                          _unitController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemNameController,
                    enabled: isCustomProduct,
                    decoration: InputDecoration(
                      labelText: 'Tên món *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.shopping_basket),
                      suffixIcon: isCustomProduct ? null : const Icon(Icons.lock, size: 18),
                    ),
                    autofocus: isCustomProduct,
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
                          enabled: isCustomProduct,
                          decoration: InputDecoration(
                            labelText: 'Đơn vị *',
                            hintText: 'vd: kg, quả, gói...',
                            border: const OutlineInputBorder(),
                            suffixIcon: isCustomProduct ? null : const Icon(Icons.lock, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Thêm món', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
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

  void _handleMenuAction(String action, ShoppingListProvider provider, ShoppingList list) async {
    switch (action) {
      case 'start':
        final success = await provider.updateShoppingListStatus(list.id, ShoppingListStatus.SHOPPING, version: list.version ?? 0);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể cập nhật trạng thái. ${provider.errorMessage ?? "Vui lòng thử lại"}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Tải lại',
                textColor: Colors.white,
                onPressed: () => _loadData(),
              ),
            ),
          );
        }
        break;
      case 'complete':
        final success = await provider.updateShoppingListStatus(list.id, ShoppingListStatus.COMPLETED, version: list.version ?? 0);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể cập nhật trạng thái. ${provider.errorMessage ?? "Vui lòng thử lại"}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Tải lại',
                textColor: Colors.white,
                onPressed: () => _loadData(),
              ),
            ),
          );
        }
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
      case ShoppingListStatus.PLANNING:
        return Colors.orange;
      case ShoppingListStatus.SHOPPING:
        return Colors.blue;
      case ShoppingListStatus.COMPLETED:
        return Colors.green;
    }
  }

  String _getStatusText(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.PLANNING:
        return 'Đang lập';
      case ShoppingListStatus.SHOPPING:
        return 'Đang mua';
      case ShoppingListStatus.COMPLETED:
        return 'Hoàn thành';
    }
  }

  void _selectAll() {
    final provider = context.read<ShoppingListProvider>();
    final items = provider.currentShoppingList?.items ?? [];
    setState(() {
      if (_selectedItems.length == items.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.clear();
        _selectedItems.addAll(items.map((item) => item.id));
      }
    });
  }

  void _handleBulkAction(String action, ShoppingListProvider provider) {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một món')),
      );
      return;
    }

    switch (action) {
      case 'mark_bought':
        _bulkMarkBought(provider, true);
        break;
      case 'mark_unbought':
        _bulkMarkBought(provider, false);
        break;
      case 'delete':
        _bulkDelete(provider);
        break;
    }
  }

  void _bulkMarkBought(ShoppingListProvider provider, bool isBought) async {
    final items = provider.currentShoppingList?.items ?? [];
    final selectedItemsList = items.where((item) => _selectedItems.contains(item.id)).toList();
    
    for (final item in selectedItemsList) {
      if (item.isBought != isBought) {
        await provider.toggleItemBought(item.id, isBought, version: item.version);
      }
    }
    
    setState(() {
      _selectionMode = false;
      _selectedItems.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${selectedItemsList.length} món')),
      );
    }
  }

  void _bulkDelete(ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ${_selectedItems.length} món đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final selectedIds = _selectedItems.toList();
              
              for (final itemId in selectedIds) {
                await provider.deleteShoppingItem(itemId);
              }
              
              setState(() {
                _selectionMode = false;
                _selectedItems.clear();
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa ${selectedIds.length} món')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
