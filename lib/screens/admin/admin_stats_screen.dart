import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/token_status.dart';
import '../../services/token_service.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TokenService>();
    final active = service.activeTokens;
    final waiting = active.where((t) => t.status == TokenStatus.waiting).length;
    final nearTurn = active.where((t) => t.status == TokenStatus.nearTurn).length;
    final activeNow = active.where((t) => t.status == TokenStatus.active).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Queue Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        switch (v.toInt()) {
                          case 0:
                            return const Text('Waiting');
                          case 1:
                            return const Text('Near');
                          case 2:
                            return const Text('Active');
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: waiting.toDouble(), color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: nearTurn.toDouble(), color: Colors.orange)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: activeNow.toDouble(), color: Colors.green)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
