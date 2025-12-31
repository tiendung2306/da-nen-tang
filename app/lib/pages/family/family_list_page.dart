import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'create_family_page.dart';

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
      context.read<FamilyProvider>().fetchInvitations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách nhóm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateFamilyPage())),
          ),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          // FIX: Use the new isLoading property
          if (provider.isLoading && provider.families.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.families.isEmpty) {
            return const Center(child: Text('Bạn chưa tham gia nhóm nào.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchFamilies(),
            child: ListView.builder(
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
    final familyProvider = context.watch<FamilyProvider>();
    final isSelected = familyProvider.selectedFamily?.id == family.id;

    return Card(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text(family.name.substring(0, 1))),
        title: Text(family.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(family.leaderName ?? 'Trưởng nhóm'),
        onTap: () {
          familyProvider.setSelectedFamily(family);
          context.read<FridgeProvider>().fetchFridgeItems(family.id, isRefresh: true);
        },
      ),
    );
  }
}
