import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token_type.dart';
import '../services/token_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TokenService>();
    final data = <TokenType, int>{ for (final t in TokenType.values) t: 0 };
    for (final t in service.activeTokens) {
      data[t.type] = (data[t.type] ?? 0) + 1;
    }

    final entries = data.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Active Tokens by Service', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                        return Text(entries[idx].key.displayName.split(' ').first);
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(toY: entries[i].value.toDouble(), color: Colors.teal)],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
