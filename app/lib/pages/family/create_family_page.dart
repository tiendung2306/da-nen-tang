import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({Key? key}) : super(key: key);

  @override
  _CreateFamilyPageState createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  // Placeholder for selected members
  final List<String> _selectedMembers = [];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final familyData = {
        'name': _nameController.text,
        // TODO: Add selected member IDs to the request body when the API supports it
        // 'memberIds': _selectedMembers.map((member) => member.id).toList(),
      };

      try {
        await context.read<FamilyProvider>().createFamily(familyData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo nhóm thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tạo nhóm mới', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  child: const Text('Avatar nhóm', style: TextStyle(color: Colors.grey)),
                  // TODO: Add functionality to pick an image
                ),
              ),
              const SizedBox(height: 40),

              // Group Name
              const Text('Tên nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Tên nhóm',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên nhóm' : null,
              ),
              const SizedBox(height: 24),

              // Add Members Dropdown (Placeholder)
              const Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                hint: const Text('Thêm thành viên( ít nhất 1 thành viên)'),
                // TODO: Populate with a list of users to add
                items: [],
                onChanged: (value) {
                  // Handle member selection
                },
                validator: (value) {
                  // if (_selectedMembers.isEmpty) return 'Vui lòng thêm ít nhất 1 thành viên';
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Create Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Tạo nhóm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
