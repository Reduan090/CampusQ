import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/token.dart';
import '../models/token_type.dart';
import '../models/token_status.dart';
import 'glass_container.dart';

class TokenCard extends StatelessWidget {
  final Token token;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final bool isHistory;

  const TokenCard({
    super.key,
    required this.token,
    this.onCancel,
    this.onComplete,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  token.type.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.type.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Token: ${token.tokenNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: token.status),
              ],
            ),
            const Divider(height: 24),
            if (!isHistory) ...[
              _InfoRow(
                icon: Icons.people,
                label: 'Queue Position',
                value: '${token.queuePosition} of ${token.totalInQueue}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Estimated Wait',
                value: '${token.estimatedWaitMinutes} minutes',
              ),
            ],
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Requested',
              value: DateFormat('MMM dd, hh:mm a').format(token.requestedAt),
            ),
            if (token.completedAt != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.check_circle,
                label: 'Completed',
                value: DateFormat('MMM dd, hh:mm a').format(token.completedAt!),
              ),
            ],
            if (token.status == TokenStatus.nearTurn) ...[
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: const [
                    Icon(Icons.notification_important, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your turn is approaching! Please be ready.',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (token.status == TokenStatus.active) ...[
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "It's your turn! Please proceed now.",
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isHistory && (onCancel != null || onComplete != null)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showQrDialog(context, token),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Show QR'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  if (onComplete != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
    );
  }

  Color _getStatusColor() {
    switch (token.status) {
      case TokenStatus.waiting:
        return Colors.blue;
      case TokenStatus.nearTurn:
        return Colors.orange;
      case TokenStatus.active:
        return Colors.green;
      case TokenStatus.completed:
        return Colors.grey;
      case TokenStatus.expired:
        return Colors.red;
    }
  }
  void _showQrDialog(BuildContext context, Token token) {
    final payload = {
      'id': token.id,
      'type': token.type.name,
      'number': token.tokenNumber,
      'requestedAt': token.requestedAt.toIso8601String(),
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.7),
        title: const Text('Token QR', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 220,
          height: 220,
          child: QrImageView(
            data: payload.toString(),
            version: QrVersions.auto,
            backgroundColor: Colors.white,
            gapless: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TokenStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getTextColor(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case TokenStatus.waiting:
        return Colors.blue[100]!;
      case TokenStatus.nearTurn:
        return Colors.orange[100]!;
      case TokenStatus.active:
        return Colors.green[100]!;
      case TokenStatus.completed:
        return Colors.grey[300]!;
      case TokenStatus.expired:
        return Colors.red[100]!;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case TokenStatus.waiting:
        return Colors.blue[900]!;
      case TokenStatus.nearTurn:
        return Colors.orange[900]!;
      case TokenStatus.active:
        return Colors.green[900]!;
      case TokenStatus.completed:
        return Colors.grey[800]!;
      case TokenStatus.expired:
        return Colors.red[900]!;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
