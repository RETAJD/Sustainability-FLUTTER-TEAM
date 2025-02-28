import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OccupancyChart extends StatelessWidget {
  final List<double> data;

  OccupancyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (index) => FlSpot(index.toDouble(), data[index]),
              ),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
