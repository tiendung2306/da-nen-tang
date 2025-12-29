import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';

class FamilyDetailPage extends StatefulWidget {
  final int familyId;
  const FamilyDetailPage({Key? key, required this.familyId}) : super(key: key);

  @override
  _FamilyDetailPageState createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().selectFamily(widget.familyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading || provider.selectedFamily == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          final family = provider.selectedFamily!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(family.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: family.avatarUrl != null ? NetworkImage(family.avatarUrl!) : null,
                  child: family.avatarUrl == null ? const Text('Avatar nhóm', style: TextStyle(color: Colors.grey)) : null,
                ),
                const SizedBox(height: 32),

                // Placeholder for shopping lists
                _buildListItem(icon: Icons.article_outlined, title: 'Tên danh sách chưa hoàn thành', subtitle: 'Tên người tham gia, Trạng thái'),
                _buildListItem(icon: Icons.article_outlined, title: 'Tên danh sách chưa hoàn thành'),
                const SizedBox(height: 32),
                
                // Action buttons grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5, // Adjust ratio for button shape
                  children: [
                    _buildActionButton(text: 'Thêm thành viên', color: orangeColor, onTap: () {}),
                    _buildActionButton(text: 'Danh sách mua sắm', color: orangeColor, onTap: () {}),
                    _buildActionButton(text: 'Báo cáo chi tiêu nhóm', color: orangeColor, onTap: () {}),
                    _buildActionButton(text: 'Lên lịch cho bữa ăn', color: orangeColor, onTap: () {}),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem({required IconData icon, required String title, String? subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      ),
    );
  }

  Widget _buildActionButton({required String text, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
