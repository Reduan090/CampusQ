import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/token_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import 'dart:convert';
import '../../../models/token_status.dart';
import '../../../models/token_type.dart';

class AdminPendingTokensScreen extends StatelessWidget {
  const AdminPendingTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
    final userService = context.watch<UserService>();
    final pending = tokenService.pendingTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Token Requests'),
      ),
      body: pending.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final token = pending[index];
                final UserModel? user = userService.getUserById(token.userId);
                ImageProvider? avatarImage;
                if (user?.profilePictureBase64 != null && user!.profilePictureBase64!.isNotEmpty) {
                  try {
                    avatarImage = MemoryImage(base64Decode(user.profilePictureBase64!));
                  } catch (_) {}
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? Text(
                                      (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user?.name ?? 'Unknown User',
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          token.type.displayName,
                                          style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${user?.studentId ?? '-'} • Dept: ${user?.department ?? '-'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Token: ${token.tokenNumber}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(token.status.displayName),
                              backgroundColor: Colors.orange.shade50,
                            ),
                          ],
                        ),
                        if (token.message != null && token.message!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Message:',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            token.message!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showRejectDialog(context, tokenService, token.id);
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showApprovalDialog(context, tokenService, token.id);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showApprovalDialog(BuildContext context, TokenService service, String tokenId) {
    final messageController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Approve Token Request'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add an approval message (optional):'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Please bring your ID card',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Set validity period (optional):'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate == null
                        ? 'Select Date'
                        : 'Valid until: ${selectedDate!.toString().split(' ')[0]}',
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => selectedDate = null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear date'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                service.approveToken(
                  tokenId,
                  approvalMessage: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                  validUntil: selectedDate,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token approved successfully')),
                );
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, TokenService service, String tokenId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Token Request'),
        content: const Text('Are you sure you want to reject this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.rejectToken(tokenId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token rejected')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
