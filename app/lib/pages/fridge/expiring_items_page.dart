import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/providers/fridge_provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/notification/expiry_notification_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị danh sách nguyên liệu sắp hết hạn
class ExpiringItemsPage extends StatefulWidget {
  const ExpiringItemsPage({Key? key}) : super(key: key);

  @override
  State<ExpiringItemsPage> createState() => _ExpiringItemsPageState();
}

class _ExpiringItemsPageState extends State<ExpiringItemsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedFamilyId = context.read<FamilyProvider>().selectedFamily?.id;
      if (selectedFamilyId != null) {
        context.read<FridgeProvider>().fetchFridgeItems(selectedFamilyId, isRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nguyên liệu sắp hết hạn'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Consumer<FridgeProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final selectedFamilyId = context.read<FamilyProvider>().selectedFamily?.id;
                      if (selectedFamilyId != null) {
                        provider.fetchFridgeItems(selectedFamilyId, isRefresh: true);
                      }
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final expiringItems = ExpiryNotificationService.getItemsNeedingNotification(provider.items);

          if (expiringItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Tất cả nguyên liệu đều tốt!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có nguyên liệu nào sắp hết hạn',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Phân loại theo mức độ nghiêm trọng
          final criticalItems = expiringItems.where((item) => 
            ExpiryNotificationService.getSeverity(item) == 'critical').toList();
          final warningItems = expiringItems.where((item) => 
            ExpiryNotificationService.getSeverity(item) == 'warning').toList();

          return RefreshIndicator(
            onRefresh: () async {
              final selectedFamilyId = context.read<FamilyProvider>().selectedFamily?.id;
              if (selectedFamilyId != null) {
                await provider.fetchFridgeItems(selectedFamilyId, isRefresh: true);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tổng quan
                _buildSummaryCard(expiringItems.length, criticalItems.length, warningItems.length),
                const SizedBox(height: 16),

                // Danh sách khẩn cấp (≤ 24h)
                if (criticalItems.isNotEmpty) ...[
                  _buildSectionHeader(
                    '⚠️ Khẩn cấp (≤ 24 giờ)',
                    criticalItems.length,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  ...criticalItems.map((item) => _buildExpiringItemCard(item, true)),
                  const SizedBox(height: 16),
                ],

                // Danh sách cảnh báo (≤ 3 ngày)
                if (warningItems.isNotEmpty) ...[
                  _buildSectionHeader(
                    '⏰ Cảnh báo (≤ 3 ngày)',
                    warningItems.length,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  ...warningItems.map((item) => _buildExpiringItemCard(item, false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(int total, int critical, int warning) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[100]!, Colors.orange[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'Tổng số: $total nguyên liệu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Khẩn cấp', critical, Colors.red),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem('Cảnh báo', warning, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiringItemCard(FridgeItem item, bool isCritical) {
    final expirationDate = item.expirationDate;
    final daysUntil = item.daysUntilExpiration ?? 0;
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCritical ? Colors.red[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLocationIcon(item.location),
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customProductName ?? item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        daysUntil <= 0 ? 'HẾT HẠN' : '$daysUntil',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (daysUntil > 0)
                        const Text(
                          'ngày',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Hạn SD: ${expirationDate != null ? dateFormat.format(expirationDate) : "Không rõ"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(Icons.place, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _getLocationName(item.location),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.note!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location.toUpperCase()) {
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

  String _getLocationName(String location) {
    switch (location.toUpperCase()) {
      case 'FREEZER':
        return 'Ngăn đông';
      case 'COOLER':
        return 'Ngăn mát';
      case 'PANTRY':
        return 'Kệ bếp';
      default:
        return location;
    }
  }
}
