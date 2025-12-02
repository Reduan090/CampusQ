import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import 'admin_queues_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_settings_screen.dart';
import 'pending_tokens_screen.dart';
import 'manage_users_screen.dart';
import 'notices_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      _AdminDashboard(),
      AdminPendingTokensScreen(),
      AdminQueuesScreen(),
      AdminManageUsersScreen(),
      AdminNoticesScreen(),
      AdminStatsScreen(),
      AdminSettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
    final tokenCount = tokenService.activeTokens.length;
    final pendingCount = tokenService.pendingTokens.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.pending_actions_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.pending_actions),
                ),
                label: const Text('Pending'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: tokenCount > 0,
                  label: Text('$tokenCount'),
                  child: const Icon(Icons.view_list_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: tokenCount > 0,
                  label: Text('$tokenCount'),
                  child: const Icon(Icons.view_list),
                ),
                label: const Text('Queues'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Notices'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: Text('Stats'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _tabs[_index]),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();
    final pending = tokenService.pendingTokens.length;
    final active = tokenService.activeTokens.length;
    final completed = tokenService.historyTokens.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Overview',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickStatCard(
                title: 'Pending Approvals',
                value: pending.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange.shade700,
                onTap: () {},
              ),
              _QuickStatCard(
                title: 'Active Tokens',
                value: active.toString(),
                icon: Icons.confirmation_number,
                color: Colors.blue.shade700,
                onTap: () {},
              ),
              _QuickStatCard(
                title: 'Completed',
                value: completed.toString(),
                icon: Icons.check_circle,
                color: Colors.green.shade700,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use the navigation rail to manage pending tokens, users, notices, and view statistics.',
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
