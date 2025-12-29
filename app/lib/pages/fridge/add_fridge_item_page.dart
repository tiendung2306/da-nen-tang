import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:intl/intl.dart';

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
  final _locationController = TextEditingController();
  DateTime? _expiryDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final itemData = {
        'name': _nameController.text,
        'quantity': double.tryParse(_quantityController.text),
        'unit': _unitController.text,
        'location': _locationController.text,
        'expiryDate': _expiryDate!.toIso8601String(),
        // TODO: Add other fields like purchaseDate, imageUrl if needed
      };

      context.read<FridgeProvider>().addFridgeItem(itemData).then((_) {
        // Check if the widget is still mounted before popping
        if (mounted) {
          Navigator.of(context).pop();
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên thực phẩm'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Đơn vị (ví dụ: kg, quả, hộp)'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Vị trí (ví dụ: ngăn mát)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'Chưa chọn ngày hết hạn'
                          : 'Ngày hết hạn: ${DateFormat.yMd().format(_expiryDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Chọn ngày'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Thêm Thực Phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
