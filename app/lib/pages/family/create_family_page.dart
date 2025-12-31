import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:image_picker/image_picker.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({Key? key}) : super(key: key);

  @override
  _CreateFamilyPageState createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _membersController = TextEditingController();
  final List<UserInfo> _selectedMembers = [];
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    context.read<FriendProvider>().fetchFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final familyData = {
        'name': _nameController.text,
        'friendIds': _selectedMembers.map((member) => member.id).toList(),
      };

      final success = await context.read<FamilyProvider>().createFamily(familyData, image: _selectedImage);

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showMemberSelectionDialog() {
    final friends = context.read<FriendProvider>().friends;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final tempList = List<UserInfo>.from(_selectedMembers);
        return AlertDialog(
          title: const Text('Chọn thành viên'),
          content: StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = tempList.any((member) => member.id == friend.id);
                  return CheckboxListTile(
                    title: Text(friend.fullName),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          tempList.add(friend);
                        } else {
                          tempList.removeWhere((member) => member.id == friend.id);
                        }
                      });
                    },
                  );
                },
              ),
            );
          }),
          actions: <Widget>[
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Xác nhận'),
              onPressed: () {
                setState(() {
                  _selectedMembers.clear();
                  _selectedMembers.addAll(tempList);
                  _membersController.text = _selectedMembers.map((m) => m.fullName).join(', ');
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhóm mới')),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // ... (UI remains largely the same)
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên nhóm')),
                  TextFormField(controller: _membersController, readOnly: true, onTap: _showMemberSelectionDialog, decoration: const InputDecoration(labelText: 'Thêm thành viên')),
                  provider.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: () => _submitForm(context), child: const Text('Tạo nhóm')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
