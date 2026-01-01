import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/family_model.dart'; // Import Family model
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/pages/fridge/add_fridge_item_page.dart';
import 'package:flutter_boilerplate/services/notification/expiry_notification_service.dart';
import 'package:flutter_boilerplate/pages/fridge/expiring_items_page.dart';

class FridgePage extends StatefulWidget {
  const FridgePage({Key? key}) : super(key: key);

  @override
  _FridgePageState createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final fridgeProvider = context.read<FridgeProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final selectedFamilyId = familyProvider.selectedFamily?.id;

    if (selectedFamilyId != null) {
      fridgeProvider.fetchFridgeItems(selectedFamilyId, isRefresh: true);
      familyProvider.fetchFamilyMembers(selectedFamilyId);
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
    _searchController.dispose();
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
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
              child: DropdownButtonFormField<Family>(
                value: selectedFamily,
                decoration: const InputDecoration(
                  labelText: 'Nhóm gia đình',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: familyProvider.families.map((Family family) {
                  return DropdownMenuItem<Family>(value: family, child: Text(family.name));
                }).toList(),
                onChanged: (Family? newFamily) {
                  if (newFamily != null) {
                    familyProvider.setSelectedFamily(newFamily);
                    familyProvider.fetchFamilyMembers(newFamily.id);
                    context.read<FridgeProvider>().fetchFridgeItems(newFamily.id, isRefresh: true);
                  }
                },
              ),
            ),
          // Hiển thị thành viên nhóm
          if (selectedFamily != null)
            _buildMembersBar(context, familyProvider),
          // Cảnh báo hết hạn
          if (selectedFamily != null)
            _buildExpiryWarningBanner(context),
          // Thanh tìm kiếm
          if (selectedFamily != null)
            _buildSearchBar(context),
          // Thanh chọn ngăn và sắp xếp
          if (selectedFamily != null)
            _buildLocationFilterBar(context),
          if (selectedFamily != null)
            _buildSortBar(context),
          Expanded(
            child: _buildFridgeContent(selectedFamily),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersBar(BuildContext context, FamilyProvider familyProvider) {
    final members = familyProvider.members;
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Thành viên (${members.length})',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showMembersDialog(context, members),
                icon: const Icon(Icons.info_outline, size: 14),
                label: const Text('Chi tiết', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _MemberAvatar(member: member),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog(BuildContext context, List<FamilyMember> members) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.group, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Thành viên (${members.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                  child: member.avatarUrl == null ? Text(member.fullName[0].toUpperCase()) : null,
                ),
                title: Text(member.fullName),
                subtitle: Text(member.nickname ?? member.username),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.role == 'LEADER' ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.role == 'LEADER' ? 'Trưởng nhóm' : 'Thành viên',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryWarningBanner(BuildContext context) {
    return Consumer<FridgeProvider>(
      builder: (context, provider, child) {
        final items = provider.items;
        if (items.isEmpty) return const SizedBox.shrink();

        final itemsNeedingNotification = ExpiryNotificationService.getItemsNeedingNotification(items);
        if (itemsNeedingNotification.isEmpty) return const SizedBox.shrink();

        final critical = itemsNeedingNotification.where((item) => 
          ExpiryNotificationService.getSeverity(item) == 'critical').length;
        final warning = itemsNeedingNotification.where((item) => 
          ExpiryNotificationService.getSeverity(item) == 'warning').length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: critical > 0 
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : [Colors.orange[50]!, Colors.orange[100]!],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: critical > 0 ? Colors.red[300]! : Colors.orange[300]!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExpiringItemsPage(),
                ),
              );
            },
            child: Row(
              children: [
                Icon(
                  critical > 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                  color: critical > 0 ? Colors.red[700] : Colors.orange[700],
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        critical > 0 ? '⚠️ Cảnh báo khẩn cấp!' : '⏰ Thông báo hết hạn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: critical > 0 ? Colors.red[900] : Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ExpiryNotificationService.getSummaryMessage(items),
                        style: TextStyle(
                          fontSize: 11,
                          color: critical > 0 ? Colors.red[800] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: critical > 0 ? Colors.red[700] : Colors.orange[700],
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm thực phẩm...',
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildLocationFilterBar(BuildContext context) {
    return Consumer<FridgeProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.kitchen, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Ngăn:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Tất cả',
                        icon: Icons.grid_view,
                        isSelected: provider.currentLocationFilter == FridgeLocationFilter.all,
                        onTap: () => provider.setLocationFilter(FridgeLocationFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Ngăn đông',
                        icon: Icons.ac_unit,
                        isSelected: provider.currentLocationFilter == FridgeLocationFilter.freezer,
                        onTap: () => provider.setLocationFilter(FridgeLocationFilter.freezer),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Ngăn mát',
                        icon: Icons.kitchen,
                        isSelected: provider.currentLocationFilter == FridgeLocationFilter.cooler,
                        onTap: () => provider.setLocationFilter(FridgeLocationFilter.cooler),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Kệ bếp',
                        icon: Icons.shelves,
                        isSelected: provider.currentLocationFilter == FridgeLocationFilter.pantry,
                        onTap: () => provider.setLocationFilter(FridgeLocationFilter.pantry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortBar(BuildContext context) {
    return Consumer<FridgeProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.sort, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Sắp xếp:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Sắp hết hạn',
                        icon: Icons.warning_amber_outlined,
                        isSelected: provider.currentSort == FridgeSortType.expirationOldest,
                        onTap: () => provider.setSort(FridgeSortType.expirationOldest),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Còn lâu hết hạn',
                        icon: Icons.schedule,
                        isSelected: provider.currentSort == FridgeSortType.expirationNewest,
                        onTap: () => provider.setSort(FridgeSortType.expirationNewest),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Tên A-Z',
                        icon: Icons.sort_by_alpha,
                        isSelected: provider.currentSort == FridgeSortType.nameAZ,
                        onTap: () => provider.setSort(FridgeSortType.nameAZ),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Tên Z-A',
                        icon: Icons.sort_by_alpha,
                        isSelected: provider.currentSort == FridgeSortType.nameZA,
                        onTap: () => provider.setSort(FridgeSortType.nameZA),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

        // Áp dụng search filter
        var sortedItems = provider.sortedItems;
        if (_searchQuery.isNotEmpty) {
          sortedItems = sortedItems.where((item) {
            return item.productName.toLowerCase().contains(_searchQuery) ||
                   (item.customProductName?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        // Hiển thị empty state nếu không tìm thấy
        if (sortedItems.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy "$_searchQuery"',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchFridgeItems(selectedFamily.id, isRefresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: sortedItems.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == sortedItems.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
              }
              return FridgeListItem(item: sortedItems[index]);
            },
          ),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FridgeListItem extends StatelessWidget {
  final FridgeItem item;
  const FridgeListItem({Key? key, required this.item}) : super(key: key);

  String _buildStatusText() {
    if (item.isExpired) return 'Đã hết hạn';
    if (item.isExpiringSoon && item.daysUntilExpiration != null) return 'Còn ${item.daysUntilExpiration} ngày';
    return 'Còn dùng được';
  }

  String _getLocationName() {
    switch (item.location.toUpperCase()) {
      case 'FREEZER':
        return 'Ngăn đông';
      case 'COOLER':
        return 'Ngăn mát';
      case 'PANTRY':
        return 'Kệ bếp';
      default:
        return item.location;
    }
  }

  Color _getStatusColor() {
    if (item.isExpired) return Colors.red;
    if (item.isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

  IconData _getLocationIcon() {
    switch (item.location.toUpperCase()) {
      case 'FREEZER':
        return Icons.ac_unit;
      case 'COOLER':
        return Icons.kitchen;
      case 'PANTRY':
        return Icons.shelves;
      default:
        return Icons.inventory_2;
    }
  }

  String _formatExpirationDate() {
    if (item.expirationDate == null) return 'Không có';
    final day = item.expirationDate!.day.toString().padLeft(2, '0');
    final month = item.expirationDate!.month.toString().padLeft(2, '0');
    final year = item.expirationDate!.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    // Xác định mức độ cảnh báo
    final severity = ExpiryNotificationService.getSeverity(item);
    final isCritical = severity == 'critical';
    final isWarning = severity == 'warning';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isCritical 
              ? Colors.red.withOpacity(0.5)
              : isWarning 
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.transparent,
          width: isCritical ? 2 : 1.5,
        ),
      ),
      color: isCritical 
          ? Colors.red[50]
          : isWarning 
              ? Colors.orange[50]
              : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner cảnh báo hết hạn nếu cần
            if (isCritical || isWarning)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCritical ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isCritical 
                            ? 'SẮP HẾT HẠN TRONG 24 GIỜ!' 
                            : 'Sắp hết hạn trong ${item.daysUntilExpiration} ngày',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Header: Tên và nút xóa
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getStatusColor().withOpacity(0.1),
                  child: Icon(_getLocationIcon(), color: _getStatusColor(), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context.read<FridgeProvider>().deleteItem(item.id),
                ),
              ],
            ),
            const Divider(height: 12, thickness: 0.5),
            // Chi tiết: Vị trí, Hạn sử dụng, Tình trạng
            Row(
              children: [
                // Vị trí
                Expanded(
                  child: _InfoChip(
                    icon: Icons.place_outlined,
                    label: 'Vị trí',
                    value: _getLocationName(),
                  ),
                ),
                // Hạn sử dụng
                Expanded(
                  child: _InfoChip(
                    icon: Icons.event_outlined,
                    label: 'Hạn SD',
                    value: _formatExpirationDate(),
                  ),
                ),
                // Tình trạng
                Expanded(
                  child: _InfoChip(
                    icon: Icons.info_outline,
                    label: 'Tình trạng',
                    value: _buildStatusText(),
                    valueColor: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final FamilyMember member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final isLeader = member.role == 'LEADER';
    
    return Tooltip(
      message: '${member.fullName}${isLeader ? ' (Trưởng nhóm)' : ''}',
      child: SizedBox(
        width: 44,
        height: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                  backgroundColor: isLeader ? Colors.orange[100] : Colors.blue[100],
                  child: member.avatarUrl == null
                      ? Text(
                          member.fullName[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isLeader ? Colors.orange[800] : Colors.blue[800],
                          ),
                        )
                      : null,
                ),
                if (isLeader)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 7, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              member.nickname ?? member.fullName.split(' ').last,
              style: const TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
