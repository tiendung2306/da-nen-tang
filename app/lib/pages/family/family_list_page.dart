import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/family/family_detail_page.dart';
import 'package:flutter_boilerplate/pages/family/create_family_page.dart'; // Import the create page
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
      context.read<FamilyProvider>().fetchFamilies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Danh sách nhóm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
            onPressed: () {
              // --- CONNECT THE ADD BUTTON ---
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateFamilyPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.families.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa tham gia nhóm nào.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CreateFamilyPage()),
                      );
                    },
                    child: const Text('Tạo Nhóm Mới'),
                  ),
                  // TODO: Add Join Family button and page
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.families.length,
            itemBuilder: (context, index) {
              final family = provider.families[index];
              return FamilyListItem(family: family);
            },
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
