import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/token.dart';
import '../models/token_status.dart';
import '../models/token_type.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

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
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeTokens.length,
        itemBuilder: (context, index) {
          final token = activeTokens[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _EnhancedTokenCard(
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

class _EnhancedTokenCard extends StatelessWidget {
  final Token token;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const _EnhancedTokenCard({
    required this.token,
    this.onCancel,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final user = userService.getUserById(token.userId);
    final color = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    token.type.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.type.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Token: ${token.tokenNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: token.status),
              ],
            ),
          ),
          
          // Student Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Student Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Name',
                        value: user?.name ?? 'N/A',
                        icon: Icons.person_outline,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Student ID',
                        value: user?.studentId ?? 'N/A',
                        icon: Icons.badge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Department',
                        value: user?.department ?? 'N/A',
                        icon: Icons.school,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Email',
                        value: user?.email ?? 'N/A',
                        icon: Icons.email,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Token Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Token Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Requested',
                  value: DateFormat('MMM dd, yyyy hh:mm a').format(token.requestedAt),
                ),
                const SizedBox(height: 8),
                if (token.validUntil != null) ...[
                  _InfoRow(
                    icon: Icons.event_available,
                    label: 'Valid Until',
                    value: DateFormat('MMM dd, yyyy hh:mm a').format(token.validUntil!),
                    valueColor: token.validUntil!.isAfter(DateTime.now()) 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  const SizedBox(height: 8),
                ],
                _InfoRow(
                  icon: Icons.people,
                  label: 'Queue Position',
                  value: '${token.queuePosition} of ${token.totalInQueue}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.timer,
                  label: 'Estimated Wait',
                  value: '~${token.estimatedWaitMinutes} minutes',
                ),
                if (token.approvalMessage != null && token.approvalMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.message, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                token.approvalMessage!,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (token.status == TokenStatus.active) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'It\'s your turn! Please proceed to the counter now.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (token.status == TokenStatus.nearTurn) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notification_important, color: Colors.orange.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your turn is approaching! Please be ready.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQrDialog(context),
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('Show QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printToken(context),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (token.status) {
      case TokenStatus.pending:
        return Colors.orange;
      case TokenStatus.approved:
      case TokenStatus.waiting:
        return Colors.blue;
      case TokenStatus.nearTurn:
        return Colors.orange;
      case TokenStatus.active:
        return Colors.green;
      case TokenStatus.rejected:
      case TokenStatus.expired:
        return Colors.red;
      case TokenStatus.completed:
        return Colors.grey;
    }
  }

  void _showQrDialog(BuildContext context) {
    final qrData = jsonEncode({
      'tokenId': token.id,
      'tokenNumber': token.tokenNumber,
      'type': token.type.name,
      'userId': token.userId,
      'status': token.status.name,
      'requestedAt': token.requestedAt.toIso8601String(),
      'queuePosition': token.queuePosition,
      'validUntil': token.validUntil?.toIso8601String(),
      'approvalMessage': token.approvalMessage,
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Token QR Code',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                token.tokenNumber,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan this QR code to view full token details',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printToken(BuildContext context) async {
    final userService = context.read<UserService>();
    final user = userService.getUserById(token.userId);

    final pdf = pw.Document();
    
    final qrData = jsonEncode({
      'tokenId': token.id,
      'tokenNumber': token.tokenNumber,
      'type': token.type.name,
      'userId': token.userId,
      'status': token.status.name,
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Virtual Token',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    token.type.displayName,
                    style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                  ),
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                
                // Token Number
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text(
                      token.tokenNumber,
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Student Details
                _buildPdfSection('Student Details', [
                  _buildPdfField('Name', user?.name ?? 'N/A'),
                  _buildPdfField('Student ID', user?.studentId ?? 'N/A'),
                  _buildPdfField('Department', user?.department ?? 'N/A'),
                  _buildPdfField('Email', user?.email ?? 'N/A'),
                ]),
                pw.SizedBox(height: 20),
                
                // Token Details
                _buildPdfSection('Token Details', [
                  _buildPdfField('Status', token.status.displayName),
                  _buildPdfField('Queue Position', '${token.queuePosition} of ${token.totalInQueue}'),
                  _buildPdfField('Requested At', DateFormat('MMM dd, yyyy hh:mm a').format(token.requestedAt)),
                  if (token.validUntil != null)
                    _buildPdfField('Valid Until', DateFormat('MMM dd, yyyy hh:mm a').format(token.validUntil!)),
                  if (token.approvalMessage != null && token.approvalMessage!.isNotEmpty)
                    _buildPdfField('Admin Message', token.approvalMessage!),
                ]),
                pw.SizedBox(height: 30),
                
                // QR Code
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.BarcodeWidget(
                      data: qrData,
                      barcode: pw.Barcode.qrCode(),
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Scan for full details',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Generated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(children: children),
        ),
      ],
    );
  }

  pw.Widget _buildPdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: _getTextColor(),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getTextColor() {
    switch (status) {
      case TokenStatus.pending:
        return Colors.orange[900]!;
      case TokenStatus.approved:
      case TokenStatus.waiting:
        return Colors.blue[900]!;
      case TokenStatus.nearTurn:
        return Colors.orange[900]!;
      case TokenStatus.active:
        return Colors.green[900]!;
      case TokenStatus.rejected:
      case TokenStatus.expired:
        return Colors.red[900]!;
      case TokenStatus.completed:
        return Colors.grey[800]!;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
