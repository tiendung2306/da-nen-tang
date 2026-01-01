import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/shopping/shopping_list_detail_page.dart';
import 'package:flutter_boilerplate/pages/shopping/create_shopping_list_page.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamily = familyProvider.selectedFamily;
    if (selectedFamily != null) {
      context.read<ShoppingListProvider>().fetchShoppingLists(selectedFamily.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách mua sắm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Family selector
              Consumer<FamilyProvider>(
                builder: (context, familyProvider, child) {
                  final families = familyProvider.families;
                  final selected = familyProvider.selectedFamily;
                  
                  if (families.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () => _showFamilyPicker(context, familyProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selected?.name ?? 'Chọn nhóm',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Đang lập'),
                  Tab(text: 'Đang mua'),
                  Tab(text: 'Hoàn thành'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListView(provider, ShoppingListStatus.DRAFT),
              _buildListView(provider, ShoppingListStatus.SHOPPING),
              _buildListView(provider, ShoppingListStatus.COMPLETED),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateShoppingListPage()),
          ).then((_) => _loadData());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showFamilyPicker(BuildContext context, FamilyProvider familyProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chọn nhóm gia đình',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...familyProvider.families.map((family) {
                final isSelected = family.id == familyProvider.selectedFamily?.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.green : Colors.grey[300],
                    child: Icon(
                      Icons.group,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    family.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.green : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    familyProvider.setSelectedFamily(family);
                    Navigator.pop(context);
                    _loadData();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListView(ShoppingListProvider provider, ShoppingListStatus status) {
    final lists = provider.shoppingLists.where((list) => list.status == status).toList();

    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(status),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          return _ShoppingListCard(
            shoppingList: lists[index],
            onTap: () => _openDetail(lists[index]),
          );
        },
      ),
    );
  }

  IconData _getEmptyIcon(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.DRAFT:
        return Icons.edit_note;
      case ShoppingListStatus.SHOPPING:
        return Icons.shopping_cart_outlined;
      case ShoppingListStatus.COMPLETED:
        return Icons.check_circle_outline;
    }
  }

  String _getEmptyMessage(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.DRAFT:
        return 'Chưa có danh sách nào đang lập';
      case ShoppingListStatus.SHOPPING:
        return 'Chưa có danh sách nào đang mua';
      case ShoppingListStatus.COMPLETED:
        return 'Chưa hoàn thành danh sách nào';
    }
  }

  void _openDetail(ShoppingList list) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShoppingListDetailPage(shoppingListId: list.id),
      ),
    ).then((_) => _loadData());
  }
}

class _ShoppingListCard extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback onTap;

  const _ShoppingListCard({
    required this.shoppingList,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shoppingList.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shoppingList.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            shoppingList.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.shopping_basket_outlined,
                    '${shoppingList.totalItems} món',
                  ),
                  const SizedBox(width: 12),
                  if (shoppingList.totalItems > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã mua: ${shoppingList.boughtItems}/${shoppingList.totalItems}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${(shoppingList.progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: shoppingList.progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (shoppingList.status) {
      case ShoppingListStatus.DRAFT:
        return Colors.orange;
      case ShoppingListStatus.SHOPPING:
        return Colors.blue;
      case ShoppingListStatus.COMPLETED:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (shoppingList.status) {
      case ShoppingListStatus.DRAFT:
        return Icons.edit_note;
      case ShoppingListStatus.SHOPPING:
        return Icons.shopping_cart;
      case ShoppingListStatus.COMPLETED:
        return Icons.check_circle;
    }
  }
}
