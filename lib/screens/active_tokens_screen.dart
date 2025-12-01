import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token.dart';
import '../models/token_status.dart';
import '../services/token_service.dart';
import '../widgets/token_card.dart';

class ActiveTokensScreen extends StatelessWidget {
  const ActiveTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
    final activeTokens = tokenService.activeTokens;

    if (activeTokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Tokens',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Request a token to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeTokens.length,
        itemBuilder: (context, index) {
          final token = activeTokens[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TokenCard(
              token: token,
              onCancel: () => _showCancelDialog(context, token),
              onComplete: token.status == TokenStatus.active
                  ? () => _showCompleteDialog(context, token)
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Token token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Token'),
        content: Text(
            'Are you sure you want to cancel token ${token.tokenNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              context.read<TokenService>().cancelToken(token.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token cancelled')),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, Token token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Token'),
        content: Text(
            'Mark token ${token.tokenNumber} as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              context.read<TokenService>().completeToken(token.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token completed')),
              );
            },
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
  }
}
