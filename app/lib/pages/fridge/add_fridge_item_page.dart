import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:intl/intl.dart';

enum FridgeLocation { FREEZER, FRIDGE, PANTRY }

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
  FridgeLocation _location = FridgeLocation.FRIDGE;

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

      // FIX: Send quantity as a String to match BigDecimal on the backend.
      final itemData = {
        'familyId': familyId,
        'customProductName': _nameController.text,
        'quantity': _quantityController.text, // Send as String
        'unit': _unitController.text,
        'expirationDate': _expirationDate?.toIso8601String().split('T').first,
        'location': _location.toString().split('.').last,
      };

      // Keep the rest of the logic the same
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
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên thực phẩm'), validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null),
              TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Số lượng'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? 'Vui lòng nhập số lượng' : null),
              TextFormField(controller: _unitController, decoration: const InputDecoration(labelText: 'Đơn vị'), validator: (v) => v!.isEmpty ? 'Vui lòng nhập đơn vị' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<FridgeLocation>(
                value: _location,
                decoration: const InputDecoration(labelText: 'Vị trí', border: OutlineInputBorder()),
                items: FridgeLocation.values.map((loc) => DropdownMenuItem(value: loc, child: Text(loc.name))).toList(),
                onChanged: (val) => setState(() => _location = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(_expirationDate == null ? 'Chưa chọn ngày hết hạn' : 'Ngày hết hạn: ${DateFormat.yMd().format(_expirationDate!)}')),
                  TextButton(onPressed: () => _selectDate(context), child: const Text('Chọn ngày')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _submitForm, child: const Text('Thêm Thực Phẩm')),
            ],
          ),
        ),
      ),
    );
  }
}
