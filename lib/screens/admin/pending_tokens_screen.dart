import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/token_service.dart';
import '../../../models/token_status.dart';
import '../../../models/token_type.dart';

class AdminPendingTokensScreen extends StatelessWidget {
  const AdminPendingTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(token.type.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    token.type.displayName,
                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    token.tokenNumber,
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
                                tokenService.approveToken(token.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Token approved')),
                                );
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
