import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/product_provider.dart';
import 'package:flutter_boilerplate/models/product_model.dart';
import 'package:intl/intl.dart';

// FIX: Đổi FRIDGE thành COOLER để khớp với backend
enum FridgeLocation { FREEZER, COOLER, PANTRY }

class AddFridgeItemPage extends StatefulWidget {
  const AddFridgeItemPage({Key? key}) : super(key: key);

  @override
  _AddFridgeItemPageState createState() => _AddFridgeItemPageState();
}

class _AddFridgeItemPageState extends State<AddFridgeItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  DateTime? _expirationDate;
  FridgeLocation _location = FridgeLocation.COOLER;
  
  Category? _selectedCategory;
  Product? _selectedProduct;
  bool _isCustomProduct = true;
  List<Category> _availableCategories = [];
  List<Product> _availableProducts = [];

  @override
  void initState() {
    super.initState();
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

  void _onCategoryChanged(Category? category) {
    setState(() {
      _selectedCategory = category;
      _selectedProduct = null;
      _isCustomProduct = true;
      _nameController.clear();
      _unitController.clear();
    });
  }

  void _onProductChanged(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _isCustomProduct = false;
        _nameController.text = product.name;
        _unitController.text = product.defaultUnit;
        
        // Auto-set expiration date based on avgShelfLife (updates every time product changes)
        if (product.avgShelfLife != null) {
          _expirationDate = DateTime.now().add(Duration(days: product.avgShelfLife!));
        }
      } else {
        _isCustomProduct = true;
        _nameController.clear();
        _unitController.clear();
        _expirationDate = null;
      }
    });
  }

  List<Product> _getFilteredProducts() {
    if (_selectedCategory == null) {
      return _availableProducts;
    }
    return _availableProducts.where((product) {
      return product.categories?.any((cat) => cat.id == _selectedCategory!.id) ?? false;
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() => _expirationDate = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final familyProvider = context.read<FamilyProvider>();
      final familyId = familyProvider.selectedFamily?.id;

      if (familyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không tìm thấy ID gia đình.'), backgroundColor: Colors.red));
        return;
      }

      // Build item data with productId if selected, otherwise customProductName
      final itemData = <String, dynamic>{
        'familyId': familyId,
        'quantity': _quantityController.text.trim(),
        'unit': _unitController.text.trim(),
        'location': _location.toString().split('.').last,
      };

      // Add productId or customProductName
      if (_selectedProduct != null) {
        itemData['masterProductId'] = _selectedProduct!.id;
      } else {
        final customName = _nameController.text.trim();
        if (customName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập tên thực phẩm'), backgroundColor: Colors.red),
          );
          return;
        }
        itemData['customProductName'] = customName;
      }

      // Add expiration date if set
      if (_expirationDate != null) {
        itemData['expirationDate'] = _expirationDate!.toIso8601String().split('T').first;
      }

      // Debug: print data being sent
      print('Sending fridge item data: $itemData');

      context.read<FridgeProvider>().addFridgeItem(itemData).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Thực Phẩm Mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Ghi chú về trường bắt buộc
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '(*) Trường bắt buộc',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              // Chọn danh mục
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục (tùy chọn)',
                  border: OutlineInputBorder(),
                  helperText: 'Chọn danh mục để lọc nguyên liệu',
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
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              // Chọn nguyên liệu có sẵn hoặc "Khác"
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'Chọn nguyên liệu',
                  border: OutlineInputBorder(),
                  helperText: 'Chọn từ danh sách hoặc "Khác" để nhập tên riêng',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                items: [
                  const DropdownMenuItem<Product>(
                    value: null,
                    child: Text('➕ Khác (nhập tên riêng)'),
                  ),
                  ..._getFilteredProducts().map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text(product.name),
                    );
                  }),
                ],
                onChanged: _onProductChanged,
              ),
              const SizedBox(height: 16),
              // Hiển thị thông tin sản phẩm đã chọn
              if (_selectedProduct != null) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Thông tin nguyên liệu',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedProduct!.description != null && _selectedProduct!.description!.isNotEmpty) ...[
                          Text(
                            _selectedProduct!.description!,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_selectedProduct!.avgShelfLife != null)
                          Text(
                            '📅 Hạn sử dụng trung bình: ${_selectedProduct!.avgShelfLife} ngày',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Tên thực phẩm (chỉ cho phép nhập nếu chọn "Khác")
              TextFormField(
                controller: _nameController,
                enabled: _isCustomProduct,
                decoration: InputDecoration(
                  labelText: 'Tên thực phẩm *',
                  hintText: 'VD: Thịt bò, Rau cải, Sữa tươi...',
                  helperText: _isCustomProduct 
                      ? 'Nhập tên thực phẩm bạn muốn thêm vào tủ lạnh'
                      : 'Tự động điền từ nguyên liệu đã chọn',
                  suffixIcon: _isCustomProduct ? null : const Icon(Icons.lock, size: 18),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên thực phẩm' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng *',
                  hintText: 'VD: 1, 2.5, 500...',
                  helperText: 'Chỉ nhập số (có thể dùng số thập phân)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final number = double.tryParse(v.trim());
                  if (number == null) {
                    return 'Số lượng phải là số (VD: 1, 2.5, 100)';
                  }
                  if (number <= 0) {
                    return 'Số lượng phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                enabled: _isCustomProduct,
                decoration: InputDecoration(
                  labelText: 'Đơn vị *',
                  hintText: 'VD: kg, lít, gói, hộp, quả...',
                  helperText: _isCustomProduct
                      ? 'Đơn vị tính của thực phẩm'
                      : 'Tự động điền từ nguyên liệu đã chọn',
                  suffixIcon: _isCustomProduct ? null : const Icon(Icons.lock, size: 18),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập đơn vị' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FridgeLocation>(
                value: _location,
                decoration: const InputDecoration(
                  labelText: 'Vị trí *',
                  border: OutlineInputBorder(),
                  helperText: 'Chọn nơi lưu trữ thực phẩm',
                ),
                items: FridgeLocation.values.map((loc) {
                  String displayName;
                  switch (loc) {
                    case FridgeLocation.FREEZER:
                      displayName = 'Ngăn đông';
                      break;
                    case FridgeLocation.COOLER:
                      displayName = 'Ngăn mát';
                      break;
                    case FridgeLocation.PANTRY:
                      displayName = 'Kệ bếp';
                      break;
                  }
                  return DropdownMenuItem(value: loc, child: Text(displayName));
                }).toList(),
                onChanged: (val) => setState(() => _location = val!),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày hết hạn (tùy chọn)',
                  border: OutlineInputBorder(),
                  helperText: 'Giúp theo dõi và cảnh báo khi thực phẩm sắp hết hạn',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expirationDate == null
                          ? 'Chưa chọn'
                          : DateFormat('dd/MM/yyyy').format(_expirationDate!),
                      style: TextStyle(
                        color: _expirationDate == null ? Colors.grey : null,
                      ),
                    ),
                    Row(
                      children: [
                        if (_expirationDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _expirationDate = null),
                            tooltip: 'Xóa ngày',
                          ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Chọn ngày'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Thực Phẩm'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
