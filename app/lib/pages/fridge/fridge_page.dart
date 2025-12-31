import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/family_model.dart'; // Import Family model
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/pages/fridge/add_fridge_item_page.dart';

class FridgePage extends StatefulWidget {
  const FridgePage({Key? key}) : super(key: key);

  @override
  _FridgePageState createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final fridgeProvider = context.read<FridgeProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamilyId = familyProvider.selectedFamily?.id;

    if (selectedFamilyId != null) {
      fridgeProvider.fetchFridgeItems(selectedFamilyId, isRefresh: true);
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && selectedFamilyId != null) {
        fridgeProvider.fetchMoreItems(selectedFamilyId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final selectedFamily = familyProvider.selectedFamily;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ Lạnh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: selectedFamily == null
              ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nhóm để thêm đồ.')))
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFridgeItemPage())),
          )
        ],
      ),
      body: Column(
        children: [
          if (familyProvider.families.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<Family>(
                value: selectedFamily,
                decoration: const InputDecoration(labelText: 'Chọn nhóm gia đình', border: OutlineInputBorder()),
                items: familyProvider.families.map((Family family) {
                  return DropdownMenuItem<Family>(value: family, child: Text(family.name));
                }).toList(),
                onChanged: (Family? newFamily) {
                  if (newFamily != null) {
                    familyProvider.setSelectedFamily(newFamily);
                    context.read<FridgeProvider>().fetchFridgeItems(newFamily.id, isRefresh: true);
                  }
                },
              ),
            ),
          Expanded(
            child: _buildFridgeContent(selectedFamily),
          ),
        ],
      ),
    );
  }

  Widget _buildFridgeContent(Family? selectedFamily) {
    return Consumer<FridgeProvider>(
      builder: (context, provider, child) {
        if (selectedFamily == null) {
          return const Center(child: Text('Vui lòng chọn một nhóm để xem tủ lạnh.'));
        }
        if (provider.viewStatus == ViewStatus.Loading && provider.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.items.isEmpty) {
          return const Center(child: Text('Tủ lạnh trống!'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchFridgeItems(selectedFamily.id, isRefresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.items.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.items.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
              }
              return FridgeListItem(item: provider.items[index]);
            },
          ),
        );
      },
    );
  }
}

class FridgeListItem extends StatelessWidget {
  final FridgeItem item;
  const FridgeListItem({Key? key, required this.item}) : super(key: key);

  String _buildStatusText() {
    if (item.isExpired) return 'Đã hết hạn';
    if (item.isExpiringSoon && item.daysUntilExpiration != null) return 'còn ${item.daysUntilExpiration} ngày';
    return 'Còn dùng được';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.fastfood_outlined)),
        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Số lượng: ${item.quantity} ${item.unit}\nTình trạng: ${_buildStatusText()}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => context.read<FridgeProvider>().deleteItem(item.id),
        ),
      ),
    );
  }
}
