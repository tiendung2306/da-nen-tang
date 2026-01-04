import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_product_model.dart';
import '../../providers/admin_product_provider.dart';

class AdminProductManagementPage extends StatefulWidget {
  const AdminProductManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminProductManagementPage> createState() =>
      _AdminProductManagementPageState();
}

class _AdminProductManagementPageState
    extends State<AdminProductManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProductProvider>();
      provider.fetchProducts();
      provider.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AdminProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProducts(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng sản phẩm: ${provider.products.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context, provider),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm sản phẩm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Không có sản phẩm nào'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          final product = provider.products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(product.name ?? 'N/A'),
                              subtitle: Text(
                                '${product.categoryName ?? 'N/A'} - ${product.price?.toStringAsFixed(2) ?? '0.00'} ₫',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  _handleAction(value, product, provider);
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Chỉnh sửa'),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleAction(
      String action, Product product, AdminProductProvider provider) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, provider, product);
        break;
      case 'delete':
        _showConfirmDelete(context, product, provider);
        break;
    }
  }

  void _showCreateDialog(BuildContext context, AdminProductProvider provider) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    int? selectedCategoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo sản phẩm mới'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer<AdminProductProvider>(
                    builder: (context, prodProvider, _) =>
                        DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: prodProvider.categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name ?? 'N/A'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategoryId = value),
                      validator: (value) {
                        if (value == null) return 'Vui lòng chọn danh mục';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    await provider.createProduct({
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.parse(priceController.text),
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'categoryId': selectedCategoryId,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tạo sản phẩm thành công')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, AdminProductProvider provider, Product product) {
    final nameController = TextEditingController(text: product.name ?? '');
    final descriptionController =
        TextEditingController(text: product.description ?? '');
    final priceController =
        TextEditingController(text: product.price?.toString() ?? '');
    final quantityController =
        TextEditingController(text: product.quantity?.toString() ?? '');
    int? selectedCategoryId = product.categoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa sản phẩm'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer<AdminProductProvider>(
                    builder: (context, prodProvider, _) =>
                        DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: prodProvider.categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name ?? 'N/A'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategoryId = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    await provider.updateProduct(product.id ?? 0, {
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.parse(priceController.text),
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'categoryId': selectedCategoryId,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật thành công')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDelete(
      BuildContext context, Product product, AdminProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text(
            'Bạn có chắc muốn xóa sản phẩm "${product.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteProduct(product.id ?? 0);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
