import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PowerConsumptionChart extends StatelessWidget {
  final List<double> deviceData;
  final String folderName;

  PowerConsumptionChart({required this.deviceData, required this.folderName});

  @override
  Widget build(BuildContext context) {
    final limitedData = deviceData.take(500).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child:
          limitedData.isEmpty
              ? Center(child: Text('Brak danych do wyświetlenia na wykresie'))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '📊 Power Consumption — Folder $folderName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        backgroundColor: Colors.transparent,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 10,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 50,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  value % 50 == 0 ? 'P${value.toInt()}' : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[800],
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.green[100],
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups:
                            limitedData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final value = entry.value;

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    fromY: 0,
                                    toY: value,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade300,
                                        Colors.green.shade700,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 0,
                                      color: Colors.green[100],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ℹ️ Aggregated from 500 points for clarity and performance.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
    );
  }
}
