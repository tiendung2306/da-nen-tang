import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({Key? key}) : super(key: key);

  @override
  _CreateFamilyPageState createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _membersController = TextEditingController();
  bool _isLoading = false;
  final List<UserInfo> _selectedMembers = [];

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final familyData = {
        'name': _nameController.text,
        'friendIds': _selectedMembers.map((member) => member.id).toList(),
      };

      try {
        await context.read<FamilyProvider>().createFamily(familyData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo nhóm thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showMemberSelectionDialog() {
    final friends = context.read<FriendProvider>().friends;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final List<UserInfo> tempList = List.from(_selectedMembers);

        return AlertDialog(
          title: const Text('Chọn thành viên'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (BuildContext context, int index) {
                    final friend = friends[index];
                    final isSelected = tempList.any((member) => member.id == friend.id);
                    return CheckboxListTile(
                      title: Text(friend.name),
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
            },
          ),
          actions: <Widget>[
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Xác nhận'),
              onPressed: () {
                setState(() {
                  _selectedMembers.clear();
                  _selectedMembers.addAll(tempList);
                  _membersController.text = _selectedMembers.map((m) => m.name).join(', ');
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
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
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
              // RESTORED: Avatar
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  child: const Text('Avatar nhóm', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 40),

              // RESTORED: Group Name field
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

              // Member selection field
              const Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _membersController,
                readOnly: true,
                onTap: _showMemberSelectionDialog,
                decoration: const InputDecoration(
                  hintText: 'Thêm thành viên (ít nhất 1 thành viên)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (value) {
                  if (_selectedMembers.isEmpty) {
                    return 'Vui lòng thêm ít nhất 1 thành viên';
                  }
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
