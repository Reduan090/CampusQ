import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../services/user_service.dart';
import '../../models/token_status.dart';
import 'admin_queues_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_settings_screen.dart';
import 'pending_tokens_screen.dart';
import 'manage_users_screen.dart';
import 'notices_screen.dart';
import 'admin_profile_screen.dart';

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
      AdminProfileScreen(),
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
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle),
                label: Text('Profile'),
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
    final userService = context.watch<UserService>();
    
    final pending = tokenService.pendingTokens.length;
    final active = tokenService.activeTokens.length;
    final completed = tokenService.historyTokens
        .where((t) => t.status == TokenStatus.completed)
        .length;
    final totalUsers = userService.users.length;
    final activeUsers = userService.activeUsers.length;
    
    // Calculate completion rate
    final total = pending + active + completed;
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';
    
    // Calculate average wait time from completed tokens
    final completedTokens = tokenService.historyTokens
        .where((t) => t.status == TokenStatus.completed && t.activatedAt != null && t.completedAt != null)
        .toList();
    
    final avgWaitMinutes = completedTokens.isEmpty 
        ? 0
        : completedTokens.map((t) => t.completedAt!.difference(t.activatedAt!).inMinutes).reduce((a, b) => a + b) / completedTokens.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Last updated: ${TimeOfDay.now().format(context)}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Main metrics grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _EnhancedStatCard(
                    title: 'Pending Approvals',
                    value: pending.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange.shade700,
                    trend: pending > 5 ? '↑ High' : '→ Normal',
                    trendColor: pending > 5 ? Colors.red : Colors.green,
                  ),
                  _EnhancedStatCard(
                    title: 'Active Tokens',
                    value: active.toString(),
                    icon: Icons.confirmation_number,
                    color: Colors.blue.shade700,
                    trend: active > 10 ? '↑ Busy' : '→ Normal',
                    trendColor: active > 10 ? Colors.orange : Colors.green,
                  ),
                  _EnhancedStatCard(
                    title: 'Completed Today',
                    value: completed.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green.shade700,
                    trend: completed > 20 ? '↑ $completionRate%' : '→ $completionRate%',
                    trendColor: Colors.green,
                  ),
                  _EnhancedStatCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.purple.shade700,
                    trend: '$activeUsers Active',
                    trendColor: Colors.blue,
                  ),
                  _EnhancedStatCard(
                    title: 'Completion Rate',
                    value: '$completionRate%',
                    icon: Icons.trending_up,
                    color: Colors.teal.shade700,
                    trend: total > 0 ? '$completed/$total' : '0/0',
                    trendColor: Colors.grey,
                  ),
                  _EnhancedStatCard(
                    title: 'Avg Wait Time',
                    value: '${avgWaitMinutes.toInt()} min',
                    icon: Icons.schedule,
                    color: Colors.indigo.shade700,
                    trend: avgWaitMinutes < 15 ? '→ Fast' : '↑ Slow',
                    trendColor: avgWaitMinutes < 15 ? Colors.green : Colors.orange,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                label: 'View All Pending',
                icon: Icons.pending_actions,
                color: Colors.orange,
                onPressed: () {
                  // This would navigate to pending tab, but we're already in the same screen
                  // The parent state would need to be updated
                },
              ),
              _QuickActionButton(
                label: 'Manage Users',
                icon: Icons.people,
                color: Colors.blue,
                onPressed: () {},
              ),
              _QuickActionButton(
                label: 'Send Notice',
                icon: Icons.campaign,
                color: Colors.purple,
                onPressed: () {},
              ),
              _QuickActionButton(
                label: 'View Statistics',
                icon: Icons.insights,
                color: Colors.teal,
                onPressed: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Admin Dashboard',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use the navigation rail to manage pending tokens, active queues, users, notices, and view detailed statistics.',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ],
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

class _EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final Color trendColor;

  const _EnhancedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
