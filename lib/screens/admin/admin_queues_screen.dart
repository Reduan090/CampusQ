import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/token_status.dart';
import '../../models/token_type.dart';
import '../../services/token_service.dart';
import '../../services/user_service.dart';
import '../../widgets/token_card.dart';

class AdminQueuesScreen extends StatefulWidget {
  const AdminQueuesScreen({super.key});

  @override
  State<AdminQueuesScreen> createState() => _AdminQueuesScreenState();
}

class _AdminQueuesScreenState extends State<AdminQueuesScreen> {
  TokenStatus _selectedFilter = TokenStatus.active;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TokenService>();
    final allTokens = service.activeTokens;
    
    // Filter tokens based on selected status
    final filteredTokens = _selectedFilter == TokenStatus.active
        ? allTokens
        : allTokens.where((t) => t.status == _selectedFilter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Queues', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateTokenDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Token'),
              ),
              const SizedBox(width: 12),
              SegmentedButton<TokenStatus>(
                segments: const <ButtonSegment<TokenStatus>>[
                  ButtonSegment(value: TokenStatus.active, label: Text('Active'), icon: Icon(Icons.play_arrow)),
                  ButtonSegment(value: TokenStatus.waiting, label: Text('Waiting'), icon: Icon(Icons.hourglass_bottom)),
                  ButtonSegment(value: TokenStatus.completed, label: Text('Completed'), icon: Icon(Icons.check_circle)),
                ],
                selected: <TokenStatus>{_selectedFilter},
                onSelectionChanged: (Set<TokenStatus> selected) {
                  setState(() {
                    _selectedFilter = selected.first;
                  });
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredTokens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.view_list, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No tokens found', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTokens.length,
                  itemBuilder: (context, i) {
                    final t = filteredTokens[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TokenCard(
                        token: t,
                        isHistory: false,
                        onCancel: () => _confirmRemoveToken(context, service, t.id),
                        onComplete: t.status == TokenStatus.active ? () => service.completeToken(t.id) : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreateTokenDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    TokenType selectedType = TokenType.library;
    String? selectedUserId;
    int priority = 1;
    DateTime? validUntil;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final userService = context.read<UserService>();
          final users = userService.activeUsers;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle, color: Colors.blue),
                SizedBox(width: 12),
                Text('Create Manual Token'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a token manually for a user:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select User *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        value: selectedUserId,
                        items: users.map((user) {
                          return DropdownMenuItem(
                            value: user.uid,
                            child: Text('${user.name ?? user.email} (${user.studentId ?? "No ID"})',
                          ));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedUserId = value),
                        validator: (value) {
                          if (value == null) return 'Please select a user';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TokenType>(
                        decoration: const InputDecoration(
                          labelText: 'Token Type *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        value: selectedType,
                        items: TokenType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedType = value!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: priority > 1 ? () => setState(() => priority--) : null,
                                    ),
                                    Text('$priority', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: priority < 10 ? () => setState(() => priority++) : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() => validUntil = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                validUntil == null
                                    ? 'Set Validity'
                                    : validUntil!.toString().split(' ')[0],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add any special instructions...',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  try {
                    final tokenService = context.read<TokenService>();
                    await tokenService.requestToken(
                      selectedType,
                      message: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Token created successfully'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating token: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Token'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveToken(BuildContext context, TokenService service, String tokenId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Token'),
        content: const Text('Are you sure you want to remove this token? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.cancelToken(tokenId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Token removed successfully'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
