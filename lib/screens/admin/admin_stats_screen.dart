import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/token_status.dart';
import '../../models/token_type.dart';
import '../../services/token_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  String _selectedPeriod = 'All Time';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TokenService>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics & Analytics',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                  DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                  DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                ],
                onChanged: (value) => setState(() => _selectedPeriod = value!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Live queue status
          Text(
            'Live Queue Status',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildLiveQueueChart(service),
          
          const SizedBox(height: 40),
          
          // Token type distribution
          Text(
            'Token Type Distribution',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildTokenTypePieChart(service),
          
          const SizedBox(height: 40),
          
          // Daily completion trend
          Text(
            'Daily Completion Trend (Last 7 Days)',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildCompletionLineChart(service),
          
          const SizedBox(height: 40),
          
          // Key metrics
          Text(
            'Key Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildKeyMetrics(service),
        ],
      ),
    );
  }

  Widget _buildLiveQueueChart(TokenService service) {
    final active = service.activeTokens;
    final waiting = active.where((t) => t.status == TokenStatus.waiting).length;
    final nearTurn = active.where((t) => t.status == TokenStatus.nearTurn).length;
    final activeNow = active.where((t) => t.status == TokenStatus.active).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (waiting + nearTurn + activeNow + 5).toDouble(),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: waiting.toDouble(),
                      color: Colors.blue,
                      width: 50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: nearTurn.toDouble(),
                      color: Colors.orange,
                      width: 50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: activeNow.toDouble(),
                      color: Colors.green,
                      width: 50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
              ],
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Waiting', style: TextStyle(fontSize: 12));
                        case 1:
                          return const Text('Near Turn', style: TextStyle(fontSize: 12));
                        case 2:
                          return const Text('Active', style: TextStyle(fontSize: 12));
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenTypePieChart(TokenService service) {
    final typeMap = <TokenType, int>{};
    for (final token in service.activeTokens) {
      typeMap[token.type] = (typeMap[token.type] ?? 0) + 1;
    }

    final sections = typeMap.entries.map((entry) {
      final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
      final colorIndex = TokenType.values.indexOf(entry.key) % colors.length;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}\n${entry.key.displayName}',
        color: colors[colorIndex],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 300,
          child: sections.isEmpty
              ? const Center(child: Text('No active tokens'))
              : PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCompletionLineChart(TokenService service) {
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final count = service.historyTokens
          .where((t) =>
              t.status == TokenStatus.completed &&
              t.completedAt != null &&
              t.completedAt!.year == date.year &&
              t.completedAt!.month == date.month &&
              t.completedAt!.day == date.day)
          .length;
      spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.now().subtract(Duration(days: (6 - value.toInt())));
                      return Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(TokenService service) {
    final completed = service.historyTokens
        .where((t) => t.status == TokenStatus.completed)
        .toList();
    
    final avgWaitTime = completed.isEmpty
        ? 0
        : completed
              .where((t) => t.activatedAt != null && t.completedAt != null)
              .map((t) => t.completedAt!.difference(t.activatedAt!).inMinutes)
              .reduce((a, b) => a + b) /
          completed.where((t) => t.activatedAt != null && t.completedAt != null).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Completed',
          completed.length.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Active Now',
          service.activeTokens.length.toString(),
          Icons.play_circle,
          Colors.blue,
        ),
        _buildMetricCard(
          'Avg Wait Time',
          '${avgWaitTime.toInt()} min',
          Icons.schedule,
          Colors.orange,
        ),
        _buildMetricCard(
          'Total Pending',
          service.pendingTokens.length.toString(),
          Icons.pending,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

