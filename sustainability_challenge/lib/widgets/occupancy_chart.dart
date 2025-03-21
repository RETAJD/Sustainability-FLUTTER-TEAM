import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OccupancyChart extends StatelessWidget {
  final List<double> summerData;
  final List<double> winterData;

  OccupancyChart({required this.summerData, required this.winterData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: summerData.length.toDouble() - 1, // Zmieniamy na długość danych
          minY: [
            summerData.reduce((a, b) => a < b ? a : b),
            winterData.reduce((a, b) => a < b ? a : b),
          ].reduce((a, b) => a < b ? a : b), // Minimalna wartość z obu zestawów
          maxY: [
            summerData.reduce((a, b) => a > b ? a : b),
            winterData.reduce((a, b) => a > b ? a : b),
          ].reduce(
            (a, b) => a > b ? a : b,
          ), // Maksymalna wartość z obu zestawów
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 6, // Co 10 minut (6 × 10 min = 60 minut)
                getTitlesWidget: (value, meta) {
                  int minutes = value.toInt() * 10;
                  int hours = minutes ~/ 60;
                  int min = minutes % 60;
                  return Text(
                    "${hours.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}",
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(1));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Wykres dla danych letnich
            LineChartBarData(
              spots: List.generate(
                summerData.length,
                (index) => FlSpot(index.toDouble(), summerData[index]),
              ),
              isCurved: true,
              color: Colors.orange,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: true), // Pokazanie punktów danych
            ),
            // Wykres dla danych zimowych
            LineChartBarData(
              spots: List.generate(
                winterData.length,
                (index) => FlSpot(index.toDouble(), winterData[index]),
              ),
              isCurved: true,
              color: Colors.blue,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: true), // Pokazanie punktów danych
            ),
          ],
        ),
      ),
    );
  }
}
