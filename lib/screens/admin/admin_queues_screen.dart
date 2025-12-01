import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/token_status.dart';
import '../../services/token_service.dart';
import '../../widgets/token_card.dart';

class AdminQueuesScreen extends StatelessWidget {
  const AdminQueuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TokenService>();
    final active = service.activeTokens;

    if (active.isEmpty) {
      return const Center(child: Text('No active tokens'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (context, i) {
        final t = active[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TokenCard(
            token: t,
            isHistory: false,
            onCancel: () => service.cancelToken(t.id),
            onComplete: t.status == TokenStatus.active ? () => service.completeToken(t.id) : null,
          ),
        );
      },
    );
  }
}
