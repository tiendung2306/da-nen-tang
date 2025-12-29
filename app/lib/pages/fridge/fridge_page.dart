import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/fridge/add_fridge_item_page.dart'; // Import the new page

class FridgePage extends StatelessWidget {
  const FridgePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FridgeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {},
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập từ khóa tìm kiếm',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Danh sách thực phẩm', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        // --- CONNECT THE ADD BUTTON ---
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AddFridgeItemPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(context, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, FridgeProvider provider) {
    if (provider.viewStatus == ViewStatus.Loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }
    if (provider.items.isEmpty) {
      return const Center(child: Text('Tủ lạnh trống!'));
    }
    return ListView.builder(
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        return FridgeListItem(item: provider.items[index]);
      },
    );
  }
}

class FridgeListItem extends StatelessWidget {
  final FridgeItem item;

  const FridgeListItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ... (The rest of the FridgeListItem widget remains the same)
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: const Color(0xFFEFEFEF),
                  backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null,
                  child: item.imageUrl == null ? const Text('Ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)) : null,
                ),
                if (item.isExpiringSoon)
                  Positioned(
                    top: -5,
                    left: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('tình trạng: ${item.status}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Số lượng: ${item.quantity ?? 'N/A'} ${item.unit ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Vị trí: ${item.location ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.keyboard_arrow_up), onPressed: () {})),
                    SizedBox(height: 24, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.keyboard_arrow_down), onPressed: () {})),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () {
                    context.read<FridgeProvider>().deleteItem(item.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
