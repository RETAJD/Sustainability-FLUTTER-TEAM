import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class OccupancyScreenNew extends StatefulWidget {
  @override
  _OccupancyScreenState createState() => _OccupancyScreenState();
}

class _OccupancyScreenState extends State<OccupancyScreenNew> {
  DateTime selectedDate = DateTime(2012, 11, 24);
  String selectedInterval = '30';
  List<String> intervals = ['15', '30', '60'];
  Map<String, dynamic>? dailyData;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      String endpoint = _getEndpointForDate(selectedDate);
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/occupancy/01/$endpoint?interval=$selectedInterval',
        ),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final String formattedDate = DateFormat(
          'dd-MMM-yyyy',
        ).format(selectedDate);

        final match = data.firstWhere(
          (entry) => entry['date'] == formattedDate,
          orElse: () => null,
        );

        if (match != null) {
          setState(() {
            dailyData = match;
          });
        } else {
          setState(() {
            dailyData = null;
            error = 'No data for this date.';
          });
        }
      } else {
        setState(() {
          error = 'No data for this date';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Connection error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getEndpointForDate(DateTime date) {
    DateTime winterStart = DateTime(2012, 11, 24);
    DateTime winterEnd = DateTime(2013, 1, 9);
    DateTime summerStart = DateTime(2012, 7, 15);
    DateTime summerEnd = DateTime(2012, 8, 25);

    if ((date.isAfter(winterStart) || date.isAtSameMomentAs(winterStart)) &&
        (date.isBefore(winterEnd) || date.isAtSameMomentAs(winterEnd))) {
      return 'winter';
    } else if ((date.isAfter(summerStart) ||
            date.isAtSameMomentAs(summerStart)) &&
        (date.isBefore(summerEnd) || date.isAtSameMomentAs(summerEnd))) {
      return 'summer';
    } else {
      return 'unknown';
    }
  }

  Color _getPrimaryChartColor() {
    switch (_getEndpointForDate(selectedDate)) {
      case 'summer':
        return Colors.amber.shade600;
      case 'winter':
        return Colors.lightBlue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  LinearGradient _getChartGradient() {
    switch (_getEndpointForDate(selectedDate)) {
      case 'summer':
        return LinearGradient(
          colors: [Colors.amber.shade600, Colors.amber.shade200],
        );
      case 'winter':
        return LinearGradient(
          colors: [Colors.lightBlue.shade600, Colors.lightBlue.shade200],
        );
      default:
        return LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade300],
        );
    }
  }

  Color _getChartFillColor() {
    switch (_getEndpointForDate(selectedDate)) {
      case 'summer':
        return Colors.amber.withOpacity(0.2);
      case 'winter':
        return Colors.lightBlue.withOpacity(0.2);
      default:
        return Colors.green.withOpacity(0.2);
    }
  }

  List<FlSpot> _buildSpots() {
    final List dataPoints = dailyData?['data'] ?? [];
    return List.generate(dataPoints.length, (index) {
      final point = dataPoints[index];
      return FlSpot(index.toDouble(), (point['value'] as num).toDouble());
    });
  }

  double _getMinY() {
    final dataPoints = dailyData?['data'] ?? [];
    double minValue = double.infinity;
    for (var point in dataPoints) {
      double value = (point['value'] as num).toDouble();
      if (value < minValue) minValue = value;
    }
    return minValue - 0.5;
  }

  double _getMaxY() {
    final dataPoints = dailyData?['data'] ?? [];
    double maxValue = double.negativeInfinity;
    for (var point in dataPoints) {
      double value = (point['value'] as num).toDouble();
      if (value > maxValue) maxValue = value;
    }
    return maxValue + 0.5;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2012, 6, 1),
      lastDate: DateTime(2013, 1, 23),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFf0f9f2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3f9d5e),
        title: Text('🌿 Occupancy'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Color(0xFFd0f0d5), Color(0xFFe9f8ec)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text('Date: $formatted'),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: Icon(Icons.edit_calendar_outlined),
                        label: Text('Change'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[800],
                          side: BorderSide(color: Colors.green[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text('Interval:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedInterval,
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        iconEnabledColor: Colors.green[800],
                        items:
                            intervals.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text('$e min'),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedInterval = value;
                            });
                            fetchData();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                      : error != null
                      ? Center(
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                      : dailyData == null
                      ? Center(child: Text("No data"))
                      : LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems:
                                  (spots) =>
                                      spots.map((spot) {
                                        final time =
                                            dailyData!['data'][spot.x
                                                .toInt()]['time'];
                                        return LineTooltipItem(
                                          '$time\n${spot.y.toStringAsFixed(1)}',
                                          TextStyle(color: Colors.white),
                                        );
                                      }).toList(),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, _) {
                                  final index = value.toInt();
                                  if (index %
                                              (60 ~/
                                                  int.parse(
                                                    selectedInterval,
                                                  )) ==
                                          0 &&
                                      index < dailyData!['data'].length) {
                                    return Text(
                                      dailyData!['data'][index]['time'],
                                      style: TextStyle(fontSize: 10),
                                    );
                                  }
                                  return Container();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, _) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: Colors.green.shade200,
                                  strokeWidth: 1,
                                ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _buildSpots(),
                              isCurved: true,
                              gradient: _getChartGradient(),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _getChartFillColor(),
                              ),
                              dotData: FlDotData(show: false),
                            ),
                          ],
                          minX: 0,
                          maxX: dailyData!['data'].length.toDouble() - 1,
                          minY: _getMinY(),
                          maxY: _getMaxY(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
