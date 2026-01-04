import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
                                '${product.defaultUnit ?? 'N/A'} - Tuổi thọ: ${product.avgShelfLife ?? 'N/A'} ngày',
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
    final defaultUnitController = TextEditingController();
    final avgShelfLifeController = TextEditingController();
    final descriptionController = TextEditingController();
    List<int> selectedCategoryIds = [];
    final formKey = GlobalKey<FormState>();
    XFile? selectedImage;

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
                  TextFormField(
                    controller: defaultUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị mặc định',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: avgShelfLifeController,
                    decoration: const InputDecoration(
                      labelText: 'Tuổi thọ kệ trung bình (ngày)',
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
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setState(() {
                          selectedImage = image;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(
                      selectedImage == null
                          ? 'Chọn hình ảnh'
                          : 'Hình: ${selectedImage!.name}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AdminProductProvider>(
                    builder: (context, prodProvider, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh mục',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: prodProvider.categories.map((category) {
                              return CheckboxListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(category.name ?? 'N/A'),
                                value:
                                    selectedCategoryIds.contains(category.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCategoryIds.add(category.id ?? 0);
                                    } else {
                                      selectedCategoryIds.remove(category.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        if (selectedCategoryIds.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Vui lòng chọn ít nhất một danh mục',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                if ((formKey.currentState?.validate() ?? false) &&
                    selectedCategoryIds.isNotEmpty) {
                  try {
                    await provider.createProduct(
                      {
                        'name': nameController.text,
                        'defaultUnit': defaultUnitController.text,
                        'avgShelfLife':
                            int.tryParse(avgShelfLifeController.text),
                        'description': descriptionController.text,
                        'categoryId': selectedCategoryIds.first,
                      },
                      image: selectedImage,
                    );
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
    final defaultUnitController =
        TextEditingController(text: product.defaultUnit ?? '');
    final avgShelfLifeController =
        TextEditingController(text: product.avgShelfLife?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: product.description ?? '');
    List<int> selectedCategoryIds =
        product.categoryId != null ? [product.categoryId!] : [];
    final formKey = GlobalKey<FormState>();
    XFile? selectedImage;

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
                  TextFormField(
                    controller: defaultUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị mặc định',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: avgShelfLifeController,
                    decoration: const InputDecoration(
                      labelText: 'Tuổi thọ kệ trung bình (ngày)',
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
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setState(() {
                          selectedImage = image;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(
                      selectedImage == null
                          ? 'Chọn hình ảnh mới'
                          : 'Hình: ${selectedImage!.name}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AdminProductProvider>(
                    builder: (context, prodProvider, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh mục',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: prodProvider.categories.map((category) {
                              return CheckboxListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(category.name ?? 'N/A'),
                                value:
                                    selectedCategoryIds.contains(category.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCategoryIds.add(category.id ?? 0);
                                    } else {
                                      selectedCategoryIds.remove(category.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        if (selectedCategoryIds.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Vui lòng chọn ít nhất một danh mục',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                if ((formKey.currentState?.validate() ?? false) &&
                    selectedCategoryIds.isNotEmpty) {
                  try {
                    await provider.updateProduct(
                      product.id ?? 0,
                      {
                        'name': nameController.text,
                        'defaultUnit': defaultUnitController.text,
                        'avgShelfLife':
                            int.tryParse(avgShelfLifeController.text),
                        'description': descriptionController.text,
                        'categoryId': selectedCategoryIds.first,
                      },
                      image: selectedImage,
                    );
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
