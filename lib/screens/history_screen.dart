import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/token_service.dart';
import '../widgets/token_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
    final historyTokens = tokenService.historyTokens;

    if (historyTokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Token History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed tokens will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyTokens.length,
      itemBuilder: (context, index) {
        final token = historyTokens[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TokenCard(token: token, isHistory: true),
        );
      },
    );
  }
}
