import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class FamilyInvitationsPage extends StatefulWidget {
  const FamilyInvitationsPage({Key? key}) : super(key: key);

  @override
  State<FamilyInvitationsPage> createState() => _FamilyInvitationsPageState();
}

class _FamilyInvitationsPageState extends State<FamilyInvitationsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() => _isLoading = true);
    await context.read<FamilyProvider>().fetchInvitations();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _respondToInvitation(FamilyInvitation invitation, bool accept) async {
    final provider = context.read<FamilyProvider>();
    final success = await provider.respondToInvitation(invitation.id, accept);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept 
              ? 'Đã tham gia nhóm ${invitation.familyName}' 
              : 'Đã từ chối lời mời'),
            backgroundColor: accept ? Colors.green : Colors.grey,
          ),
        );
        if (accept) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời vào nhóm'),
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<FamilyProvider>(
              builder: (context, provider, child) {
                final invitations = provider.invitations;

                if (invitations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Không có lời mời nào',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bạn chưa nhận được lời mời vào nhóm nào',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadInvitations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
                      return _InvitationCard(
                        invitation: invitation,
                        onAccept: () => _respondToInvitation(invitation, true),
                        onDecline: () => _respondToInvitation(invitation, false),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final FamilyInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with family info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: orangeColor.withOpacity(0.2),
                  child: Icon(Icons.group, color: orangeColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.familyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Inviter info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: invitation.inviter.avatarUrl != null
                      ? NetworkImage(invitation.inviter.avatarUrl!)
                      : null,
                  child: invitation.inviter.avatarUrl == null
                      ? Text(
                          invitation.inviter.fullName.isNotEmpty
                              ? invitation.inviter.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      children: [
                        TextSpan(
                          text: invitation.inviter.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' đã mời bạn tham gia nhóm'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time
            Text(
              timeago.format(invitation.createdAt, locale: 'vi'),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Chấp nhận'),
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
