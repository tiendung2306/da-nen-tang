import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter_boilerplate/providers/auth_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/shopping_list_provider.dart';
import 'package:flutter_boilerplate/pages/shopping/shopping_list_page.dart';
import 'package:flutter_boilerplate/pages/meal_plan/meal_plan_page.dart';
import 'package:flutter_boilerplate/pages/product/product_page.dart';
import 'package:flutter_boilerplate/components/common/notification_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final familyProvider = context.read<FamilyProvider>();
      // Load families first if not loaded
      if (familyProvider.families.isEmpty) {
        familyProvider.fetchFamilies().then((_) {
          _loadStatistics();
        });
      } else {
        _loadStatistics();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload statistics when family changes
    final selectedFamily = context.watch<FamilyProvider>().selectedFamily;
    if (selectedFamily != null) {
      final fridgeStats = context.read<FridgeProvider>().statistics;
      // Only fetch if stats are null or stale
      if (fridgeStats == null) {
        _loadStatistics();
      }
    }
  }

  void _loadStatistics() {
    final selectedFamily = context.read<FamilyProvider>().selectedFamily;
    if (selectedFamily != null) {
      context.read<FridgeProvider>().fetchStatistics(selectedFamily.id);
      context.read<ShoppingListProvider>().fetchActiveShoppingLists(selectedFamily.id);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();
    List<String> greetings;
    
    if (hour >= 5 && hour < 12) {
      // Buổi sáng
      greetings = [
        'Chào buổi sáng',
        'Buổi sáng tốt lành',
        'Ngày mới vui vẻ',
        'Chúc bạn ngày mới tràn đầy năng lượng',
        'Bắt đầu ngày mới thật tuyệt vời',
      ];
    } else if (hour >= 12 && hour < 14) {
      // Buổi trưa
      greetings = [
        'Chào buổi trưa',
        'Buổi trưa vui vẻ',
        'Chúc bạn bữa trưa ngon miệng',
        'Nghỉ trưa thư giãn nhé',
        'Chúc buổi trưa tràn đầy năng lượng',
      ];
    } else if (hour >= 14 && hour < 18) {
      // Buổi chiều
      greetings = [
        'Chào buổi chiều',
        'Buổi chiều vui vẻ',
        'Chúc bạn buổi chiều năng động',
        'Chiều tốt lành',
        'Chúc buổi chiều làm việc hiệu quả',
      ];
    } else {
      // Buổi tối
      greetings = [
        'Chào buổi tối',
        'Buổi tối vui vẻ',
        'Chúc bạn buổi tối thư giãn',
        'Buổi tối tốt lành',
        'Chúc bạn buổi tối ấm áp bên gia đình',
      ];
    }
    
    return greetings[random.nextInt(greetings.length)];
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBreakdown(Map<String, int> itemsByLocation) {
    final locations = {
      'FREEZER': {'name': 'Ngăn đông', 'icon': Icons.ac_unit, 'color': Colors.blue},
      'COOLER': {'name': 'Ngăn mát', 'icon': Icons.kitchen, 'color': Colors.cyan},
      'PANTRY': {'name': 'Kệ bếp', 'icon': Icons.shelves, 'color': Colors.brown},
    };

    return Column(
      children: itemsByLocation.entries.map((entry) {
        final locationKey = entry.key.toUpperCase();
        final count = entry.value;
        final locationInfo = locations[locationKey] ?? {
          'name': entry.key,
          'icon': Icons.inventory_2,
          'color': Colors.grey,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (locationInfo['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  locationInfo['icon'] as IconData,
                  color: locationInfo['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locationInfo['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (locationInfo['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$count món',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: locationInfo['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<AuthProvider>().userInfo;
    final selectedFamily = context.watch<FamilyProvider>().selectedFamily;
    final fridgeStats = context.watch<FridgeProvider>().statistics;
    final shoppingLists = context.watch<ShoppingListProvider>().shoppingLists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đi Chợ Tiện Lợi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          NotificationBadge(iconColor: Colors.white),
        ],
      ),
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${userInfo.fullName ?? userInfo.username}! 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedFamily != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.home, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  selectedFamily.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'Chưa chọn gia đình',
                            style: TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tính năng chính',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.shopping_cart,
                                title: 'Danh sách\nmua sắm',
                                color: Colors.green,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ShoppingListPage()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.restaurant_menu,
                                title: 'Kế hoạch\nbữa ăn',
                                color: Colors.orange,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MealPlanPage()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.inventory_2,
                                title: 'Nguyên liệu',
                                color: Colors.teal,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProductPage()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tips section
                        const Text(
                          'Mẹo hôm nay 💡',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade100, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kiểm tra tủ lạnh',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Hãy kiểm tra thực phẩm sắp hết hạn để tránh lãng phí nhé!',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick stats header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thống kê nhanh 📊',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedFamily != null)
                              TextButton.icon(
                                onPressed: _loadStatistics,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Làm mới'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                        
                        // Summary card
                        if (fridgeStats != null)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[50]!, Colors.green[100]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[200]!, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  'Tổng số món',
                                  fridgeStats.totalItems.toString(),
                                  Icons.inventory_2,
                                  Colors.green[700]!,
                                ),
                                Container(width: 1, height: 40, color: Colors.green[300]),
                                _buildSummaryItem(
                                  'Đang dùng',
                                  fridgeStats.activeItems.toString(),
                                  Icons.check_circle,
                                  Colors.blue[700]!,
                                ),
                                Container(width: 1, height: 40, color: Colors.green[300]),
                                _buildSummaryItem(
                                  'Cần chú ý',
                                  '${fridgeStats.expiringSoonItems + fridgeStats.expiredItems}',
                                  Icons.warning,
                                  Colors.orange[700]!,
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        // Row 1: Fridge stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.kitchen,
                                label: 'Thực phẩm\ntrong tủ',
                                value: fridgeStats?.activeItems.toString() ?? '--',
                                color: Colors.teal,
                                onTap: () {
                                  // TODO: Navigate to Fridge page
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.warning_amber,
                                label: 'Sắp hết\nhạn',
                                value: fridgeStats?.expiringSoonItems.toString() ?? '--',
                                color: Colors.orange,
                                onTap: () {
                                  // TODO: Navigate to Expiring Items page
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.delete_outline,
                                label: 'Đã hết\nhạn',
                                value: fridgeStats?.expiredItems.toString() ?? '--',
                                color: Colors.red,
                                onTap: () {
                                  // TODO: Navigate to Expired Items
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Shopping & total stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.checklist,
                                label: 'Danh sách\nđang mua',
                                value: shoppingLists.length.toString(),
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ShoppingListPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Tổng cộng\n(kể cả hết hạn)',
                                value: fridgeStats?.totalItems.toString() ?? '--',
                                color: Colors.purple,
                                onTap: null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Empty slot for future feature
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.more_horiz, color: Colors.grey[400], size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      '---',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sắp có',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Breakdown by location
                        if (fridgeStats != null && fridgeStats.itemsByLocation != null && fridgeStats.itemsByLocation!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Phân bổ theo vị trí 📍',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLocationBreakdown(fridgeStats.itemsByLocation!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            // Shimmer effect khi đang load
            value == '--' 
                ? SizedBox(
                    width: 40,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
