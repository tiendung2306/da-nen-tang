import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';

class _ShoppingItem {
  final String name;
  final String quantity;
  bool isCompleted;
  final int itemId;
  final int version;
  final int listId;

  _ShoppingItem({
    required this.name,
    required this.quantity,
    required this.isCompleted,
    required this.itemId,
    required this.version,
    required this.listId,
  });
}

class ShoppingListSection extends StatefulWidget {
  const ShoppingListSection({Key? key}) : super(key: key);

  @override
  _ShoppingListSectionState createState() => _ShoppingListSectionState();
}

class _ShoppingListSectionState extends State<ShoppingListSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShoppingListsWithItems();
    });
  }

  Future<void> _loadShoppingListsWithItems() async {
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;
    if (selectedFamily != null) {
      final provider = context.read<ShoppingListProvider>();
      await provider.fetchActiveShoppingLists(selectedFamily.id);
      
      // Fetch items for each shopping list
      for (var list in provider.shoppingLists) {
        if (list.items == null) {
          await provider.fetchShoppingListItems(list.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, _) {
        if (provider.viewStatus == ViewStatus.Loading) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final shoppingLists = provider.shoppingLists;
        
        // Get all items from active shopping lists, separated by bought status
        final unboughtItems = <_ShoppingItem>[];
        final boughtItems = <_ShoppingItem>[];
        
        for (var list in shoppingLists) {
          if (list.items != null) {
            for (var item in list.items!) {
              final shoppingItem = _ShoppingItem(
                name: item.name,
                quantity: '${item.quantity} ${item.unit}',
                isCompleted: item.isBought,
                itemId: item.id,
                version: item.version ?? 0,
                listId: list.id,
              );
              
              if (item.isBought) {
                boughtItems.add(shoppingItem);
              } else {
                unboughtItems.add(shoppingItem);
              }
            }
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách mua hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (unboughtItems.isEmpty && boughtItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Chưa có danh sách mua hàng',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else ...[
                  _buildShoppingList('Chưa mua', unboughtItems, provider),
                  if (boughtItems.isNotEmpty) ...[
                    const Divider(height: 20, thickness: 1),
                    _buildShoppingList('Đã mua', boughtItems, provider),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShoppingList(String title, List<_ShoppingItem> items, ShoppingListProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    onChanged: (bool? value) {
                      provider.toggleItemBought(
                        item.itemId,
                        value ?? false,
                        version: item.version,
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  if (item.quantity.isNotEmpty)
                    Text(
                      item.quantity,
                      style: TextStyle(
                        color: Colors.grey[600],
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
