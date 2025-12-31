import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/pages/shopping/shopping_list_page.dart';
import 'package:flutter_boilerplate/pages/meal_plan/meal_plan_page.dart';
import 'package:image_picker/image_picker.dart';

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

  // ... (Dialogs and navigation methods remain mostly the same, but now check bool)

  void _confirmLeaveFamily(BuildContext context, Family family) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi nhóm'),
        content: Text('Bạn có chắc muốn rời khỏi nhóm "${family.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<FamilyProvider>().leaveFamily(family.id);
              if (success && mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rời nhóm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Consumer<FamilyProvider>(
            builder: (context, provider, _) {
              if (provider.selectedFamily != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'leave') {
                      _confirmLeaveFamily(context, provider.selectedFamily!);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Rời khỏi nhóm', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          // FIX: Use isLoading and check for selectedFamily
          if (provider.isLoading && provider.selectedFamily?.id != widget.familyId) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.selectedFamily == null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.selectedFamily == null) {
            return const Center(child: Text('Không tìm thấy thông tin nhóm.'));
          }

          final family = provider.selectedFamily!;
          return RefreshIndicator(
            onRefresh: () => provider.selectFamily(widget.familyId),
            child: SingleChildScrollView(
              child: Text('${family.name} Details'), // Placeholder
            ),
          );
        },
      ),
    );
  }
}
