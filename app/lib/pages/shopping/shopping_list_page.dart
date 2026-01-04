import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
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
  bool _selectionMode = false;
  final Set<int> _selectedLists = {};
  final Set<int> _expandedLists = {};
  final Set<int> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Reset expanded state khi chuyển tab
      if (!_tabController.indexIsChanging) {
        setState(() {
          _expandedLists.clear();
        });
      }
    });
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
      // Reset expanded state khi load data mới
      setState(() {
        _expandedLists.clear();
      });
      context.read<ShoppingListProvider>().fetchShoppingLists(selectedFamily.id);
      // Fetch family members để hiển thị trong dropdown edit
      familyProvider.fetchFamilyMembers(selectedFamily.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode 
            ? '${_selectedLists.length} đã chọn' 
            : 'Danh sách mua sắm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedLists.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Chọn tất cả',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleBulkAction(value, context.read<ShoppingListProvider>()),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'mark_planning', child: Text('Chuyển về "Cần mua"')),
                const PopupMenuItem(value: 'mark_shopping', child: Text('Chuyển sang "Đang mua"')),
                const PopupMenuItem(value: 'mark_completed', child: Text('Đánh dấu "Hoàn thành"')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _selectionMode = true;
                });
              },
              tooltip: 'Chọn nhiều',
            ),
          ],
        ],
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
                  Tab(text: 'Cần mua'),
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
            _buildListView(provider, ShoppingListStatus.PLANNING),
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
        backgroundColor: Colors.orange,
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
                    backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
                    child: Icon(
                      Icons.group,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    family.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.orange : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.orange)
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
          final list = lists[index];
          final isSelected = _selectedLists.contains(list.id);
          final isExpanded = _expandedLists.contains(list.id);
          final isLoadingItems = _loadingItems.contains(list.id);
          return _ShoppingListCard(
            shoppingList: list,
            isSelected: isSelected,
            selectionMode: _selectionMode,
            isExpanded: isExpanded,
            isLoadingItems: isLoadingItems,
            onTap: () {
              if (_selectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedLists.remove(list.id);
                  } else {
                    _selectedLists.add(list.id);
                  }
                });
              } else {
                _openDetail(list);
              }
            },
            onLongPress: () {
              if (!_selectionMode) {
                setState(() {
                  _selectionMode = true;
                  _selectedLists.add(list.id);
                });
              }
            },
            onEdit: () => _showEditDialog(list),
            onExpandToggle: () async {
              final isExpanded = _expandedLists.contains(list.id);
              if (!isExpanded && list.items == null) {
                // Chưa có items, cần fetch
                setState(() {
                  _loadingItems.add(list.id);
                });
                await context.read<ShoppingListProvider>().fetchShoppingListItems(list.id);
                setState(() {
                  _loadingItems.remove(list.id);
                });
              }
              setState(() {
                if (isExpanded) {
                  _expandedLists.remove(list.id);
                } else {
                  _expandedLists.add(list.id);
                }
              });
            },
            onItemToggle: (itemId, isBought, version) {
              context.read<ShoppingListProvider>().toggleItemBought(itemId, isBought, version: version);
            },
          );
        },
      ),
    );
  }

  IconData _getEmptyIcon(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.PLANNING:
        return Icons.edit_note;
      case ShoppingListStatus.SHOPPING:
        return Icons.shopping_cart_outlined;
      case ShoppingListStatus.COMPLETED:
        return Icons.check_circle_outline;
    }
  }

  String _getEmptyMessage(ShoppingListStatus status) {
    switch (status) {
      case ShoppingListStatus.PLANNING:
        return 'Chưa có danh sách cần mua';
      case ShoppingListStatus.SHOPPING:
        return 'Chưa có danh sách đang mua';
      case ShoppingListStatus.COMPLETED:
        return 'Chưa có danh sách hoàn thành';
    }
  }

  void _openDetail(ShoppingList list) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShoppingListDetailPage(shoppingListId: list.id),
      ),
    ).then((_) => _loadData());
  }

  void _selectAll() {
    final provider = context.read<ShoppingListProvider>();
    final currentTabIndex = _tabController.index;
    ShoppingListStatus status;
    
    switch (currentTabIndex) {
      case 0:
        status = ShoppingListStatus.PLANNING;
        break;
      case 1:
        status = ShoppingListStatus.SHOPPING;
        break;
      case 2:
        status = ShoppingListStatus.COMPLETED;
        break;
      default:
        status = ShoppingListStatus.PLANNING;
    }
    
    final lists = provider.shoppingLists.where((list) => list.status == status).toList();
    setState(() {
      if (_selectedLists.length == lists.length) {
        _selectedLists.clear();
      } else {
        _selectedLists.clear();
        _selectedLists.addAll(lists.map((list) => list.id));
      }
    });
  }

  void _handleBulkAction(String action, ShoppingListProvider provider) {
    if (_selectedLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một danh sách')),
      );
      return;
    }

    switch (action) {
      case 'mark_planning':
        _bulkUpdateStatus(provider, ShoppingListStatus.PLANNING);
        break;
      case 'mark_shopping':
        _bulkUpdateStatus(provider, ShoppingListStatus.SHOPPING);
        break;
      case 'mark_completed':
        _bulkUpdateStatus(provider, ShoppingListStatus.COMPLETED);
        break;
      case 'delete':
        _bulkDelete(provider);
        break;
    }
  }

  void _bulkUpdateStatus(ShoppingListProvider provider, ShoppingListStatus newStatus) async {
    final selectedListObjects = provider.shoppingLists
        .where((list) => _selectedLists.contains(list.id))
        .toList();
    
    int successCount = 0;
    int failureCount = 0;
    
    for (final list in selectedListObjects) {
      final success = await provider.updateShoppingListStatus(list.id, newStatus, version: list.version ?? 0);
      if (success) {
        successCount++;
      } else {
        failureCount++;
      }
    }
    
    setState(() {
      _selectionMode = false;
      _selectedLists.clear();
    });
    
    if (mounted) {
      if (failureCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật $successCount danh sách'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật $successCount danh sách. $failureCount thất bại (có thể do conflict)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tải lại',
              textColor: Colors.white,
              onPressed: () {
                final familyId = context.read<FamilyProvider>().selectedFamily?.id;
                if (familyId != null) {
                  provider.fetchShoppingLists(familyId);
                }
              },
            ),
          ),
        );
      }
    }
  }

  void _bulkDelete(ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ${_selectedLists.length} danh sách đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final selectedIds = _selectedLists.toList();
              
              for (final listId in selectedIds) {
                await provider.deleteShoppingList(listId);
              }
              
              setState(() {
                _selectionMode = false;
                _selectedLists.clear();
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa ${selectedIds.length} danh sách')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ShoppingList list) {
    final nameController = TextEditingController(text: list.name);
    final descriptionController = TextEditingController(text: list.description ?? '');
    FamilyMember? selectedAssignee;
    
    // Tìm FamilyMember tương ứng với assignedTo hiện tại
    final familyProvider = context.read<FamilyProvider>();
    final members = familyProvider.members;
    if (list.assignedTo != null) {
      try {
        selectedAssignee = members.firstWhere((m) => m.id == list.assignedTo!.id);
      } catch (_) {
        // Không tìm thấy member
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa danh sách'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh sách *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FamilyMember?>(
                  value: selectedAssignee,
                  decoration: const InputDecoration(
                    labelText: 'Phân công cho',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<FamilyMember?>(
                      value: null,
                      child: Text('Không phân công'),
                    ),
                    ...members.map((member) => DropdownMenuItem<FamilyMember?>(
                      value: member,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            backgroundImage: member.avatarUrl != null
                                ? NetworkImage(member.avatarUrl!)
                                : null,
                            child: member.avatarUrl == null
                                ? Text(
                                    member.fullName.isNotEmpty
                                        ? member.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedAssignee = value;
                    });
                  },
                  isExpanded: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh sách')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                final provider = context.read<ShoppingListProvider>();
                final result = await provider.updateShoppingList(
                  listId: list.id,
                  version: list.version ?? 0,
                  name: name,
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  assignedToId: selectedAssignee?.id,
                );
                
                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật thành công'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final bool selectionMode;
  final bool isSelected;
  final bool isExpanded;
  final bool isLoadingItems;
  final VoidCallback onExpandToggle;
  final Function(int itemId, bool isBought, int version) onItemToggle;

  const _ShoppingListCard({
    required this.shoppingList,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.selectionMode = false,
    this.isSelected = false,
    this.isExpanded = false,
    this.isLoadingItems = false,
    required this.onExpandToggle,
    required this.onItemToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Colors.orange.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                  ],
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
                  if (!selectionMode && shoppingList.totalItems > 0)
                    IconButton(
                      icon: isLoadingItems
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey,
                            ),
                      onPressed: isLoadingItems ? null : onExpandToggle,
                    )
                  else if (!selectionMode)
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              // Hiển thị người tạo và người được phân công
              if (shoppingList.createdBy != null || shoppingList.assignedTo != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (shoppingList.createdBy != null)
                            _buildPersonChip(
                              Icons.person_outline,
                              'Tạo bởi: ${shoppingList.createdBy!.fullName ?? shoppingList.createdBy!.email}',
                              Colors.blue,
                            ),
                          if (shoppingList.assignedTo != null)
                            _buildPersonChip(
                              Icons.assignment_ind_outlined,
                              'Phân công: ${shoppingList.assignedTo!.fullName ?? shoppingList.assignedTo!.email}',
                              Colors.green,
                            ),
                        ],
                      ),
                    ),
                    if (!selectionMode && onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Colors.grey[600],
                        onPressed: onEdit,
                        tooltip: 'Sửa thông tin',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (!selectionMode && onEdit != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.grey[600],
                    onPressed: onEdit,
                    tooltip: 'Sửa thông tin',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
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
              if (isExpanded && isLoadingItems) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (isExpanded && shoppingList.items != null && shoppingList.items!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...shoppingList.items!.map((item) => _buildItemRow(item)),
              ] else if (isExpanded && (shoppingList.items == null || shoppingList.items!.isEmpty)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Chưa có món nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isBought,
              onChanged: shoppingList.status == ShoppingListStatus.COMPLETED
                  ? null
                  : (value) {
                      onItemToggle(item.id, value ?? false, item.version ?? 0);
                    },
              activeColor: Colors.orange,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: item.isBought ? TextDecoration.lineThrough : null,
                    color: item.isBought ? Colors.grey : Colors.black87,
                  ),
                ),
                if (item.assignedTo != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Text(
                        item.assignedTo!.fullName ?? item.assignedTo!.email ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${item.quantity} ${item.unit}',
            style: TextStyle(
              fontSize: 12,
              color: item.isBought ? Colors.grey : Colors.grey[600],
            ),
          ),
        ],
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

  Widget _buildPersonChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (shoppingList.status) {
      case ShoppingListStatus.PLANNING:
        return Colors.orange;
      case ShoppingListStatus.SHOPPING:
        return Colors.blue;
      case ShoppingListStatus.COMPLETED:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (shoppingList.status) {
      case ShoppingListStatus.PLANNING:
        return Icons.edit_note;
      case ShoppingListStatus.SHOPPING:
        return Icons.shopping_cart;
      case ShoppingListStatus.COMPLETED:
        return Icons.check_circle;
    }
  }
}
