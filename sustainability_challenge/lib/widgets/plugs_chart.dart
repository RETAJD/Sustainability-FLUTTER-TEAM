import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PowerConsumptionChart extends StatelessWidget {
  final List<double> deviceData;

  PowerConsumptionChart({required this.deviceData});

  @override
  Widget build(BuildContext context) {
    final limitedData =
        deviceData.take(500).toList(); // Ograniczenie danych do 500 punktów

    return Scaffold(
      appBar: AppBar(
        title: Text('Power Consumption Chart'),
        backgroundColor: const Color.fromARGB(255, 8, 163, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            limitedData.isEmpty
                ? Center(child: Text('Brak danych do wyświetlenia na wykresie'))
                : SingleChildScrollView(
                  // Przewijanie
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: BarChart(
                            BarChartData(
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value % 10 == 0
                                            ? '${value.toInt()}'
                                            : '',
                                        style: TextStyle(
                                          fontSize: 10, // Zmniejszenie czcionki
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      return Text(
                                        index % 10 == 0
                                            ? 'P${index}'
                                            : '', // Tylko co 10 punkt
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false, // Usunięcie górnej osi
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval:
                                    10, // Linie siatki co 10 punktów
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey.withOpacity(0.2),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: true),
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
                                          color: Colors.blueAccent,
                                          width: 12, // Szerokość słupków
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ), // Zaokrąglenie słupków
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                                toY: 0,
                                                color: Colors.blue.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Data Aggregation Explanation: \n\n'
                        'The data displayed in this chart represents the average energy consumption over 500 data points. '
                        'The original dataset was aggregated to reduce the number of points for better performance and readability.',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
