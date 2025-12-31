import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/family/family_detail_page.dart';
import 'package:flutter_boilerplate/pages/family/create_family_page.dart';
import 'package:flutter_boilerplate/pages/family/join_family_page.dart';
import 'package:flutter_boilerplate/pages/family/family_invitations_page.dart';
import 'package:flutter_boilerplate/models/family_model.dart';

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({Key? key}) : super(key: key);

  @override
  _FamilyListPageState createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FamilyProvider>();
      provider.fetchFamilies();
      provider.fetchInvitations();
    });
  }

  void _navigateToCreateFamily() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateFamilyPage()),
    );
    if (result == true) {
      context.read<FamilyProvider>().fetchFamilies();
    }
  }

  void _navigateToJoinFamily() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const JoinFamilyPage()),
    );
    if (result == true) {
      context.read<FamilyProvider>().fetchFamilies();
    }
  }

  void _navigateToInvitations() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FamilyInvitationsPage()),
    );
    if (result == true) {
      context.read<FamilyProvider>().fetchFamilies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Danh sách nhóm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Invitation badge
          Consumer<FamilyProvider>(
            builder: (context, provider, _) {
              final invitationCount = provider.invitations.length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.black),
                    onPressed: _navigateToInvitations,
                  ),
                  if (invitationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$invitationCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
            onSelected: (value) {
              if (value == 'create') {
                _navigateToCreateFamily();
              } else if (value == 'join') {
                _navigateToJoinFamily();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Tạo nhóm mới'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(Icons.input, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Tham gia nhóm'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchFamilies(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (provider.families.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn chưa tham gia nhóm nào',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo nhóm mới hoặc tham gia nhóm có sẵn để bắt đầu quản lý mua sắm cùng gia đình',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCreateFamily,
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo Nhóm Mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToJoinFamily,
                        icon: const Icon(Icons.input),
                        label: const Text('Tham Gia Nhóm'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orangeColor,
                          side: BorderSide(color: orangeColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchFamilies(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.families.length,
              itemBuilder: (context, index) {
                final family = provider.families[index];
                return FamilyListItem(family: family);
              },
            ),
          );
        },
      ),
    );
  }
}

class FamilyListItem extends StatelessWidget {
  final Family family;

  const FamilyListItem({Key? key, required this.family}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ... (The rest of the widget remains the same)
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => FamilyDetailPage(familyId: family.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey[200],
                backgroundImage: family.avatarUrl != null ? NetworkImage(family.avatarUrl!) : null,
                child: family.avatarUrl == null ? const Text('Avatar nhóm', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10)) : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(family.leaderName ?? 'Họ tên trưởng nhóm', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
