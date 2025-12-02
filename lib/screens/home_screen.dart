import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'request_token_screen.dart';
import 'active_tokens_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'notices_feed_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Request, 2: Active, 3: History, 4: Notices, 5: Stats, 6: Profile

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      SizedBox.shrink(), // Dashboard built inline
      RequestTokenScreen(),
      ActiveTokensScreen(),
      HistoryScreen(),
      NoticesFeedScreen(),
      StatsScreen(),
      UserProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokenService = context.watch<TokenService>();

    final active = tokenService.activeTokens;
    final history = tokenService.historyTokens;
    final waiting = active.where((t) => t.status.name == 'waiting').length;
    final nearTurn = active.where((t) => t.status.name == 'nearTurn').length;
    final activeNow = active.where((t) => t.status.name == 'active').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Token System'),
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
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Request'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: Text('Active'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Notices'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: Text('Stats'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedIndex == 0
                  ? _Dashboard(
                      waiting: waiting,
                      nearTurn: nearTurn,
                      activeNow: activeNow,
                      historyCount: history.length,
                    )
                  : _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final int waiting;
  final int nearTurn;
  final int activeNow;
  final int historyCount;

  const _Dashboard({
    required this.waiting,
    required this.nearTurn,
    required this.activeNow,
    required this.historyCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                title: 'Waiting',
                value: waiting.toString(),
                icon: Icons.hourglass_bottom,
                color: color.primary,
              ),
              _StatCard(
                title: 'Near Turn',
                value: nearTurn.toString(),
                icon: Icons.notifications_active,
                color: Colors.orange.shade700,
              ),
              _StatCard(
                title: 'Active Now',
                value: activeNow.toString(),
                icon: Icons.play_circle_fill,
                color: Colors.teal.shade700,
              ),
              _StatCard(
                title: 'Completed',
                value: historyCount.toString(),
                icon: Icons.check_circle,
                color: Colors.green.shade700,
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
                      'Tip: Request a token early to reduce waiting time. You\'ll get a notification when it\'s almost your turn.',
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      child: Card(
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
                            color: colorScheme.onSurface.withOpacity(0.7),
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
    );
  }
}
