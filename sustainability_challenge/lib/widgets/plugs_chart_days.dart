import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DevicesScreen extends StatefulWidget {
  @override
  _DevicesScreenState createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  DateTime selectedDate = DateTime(2012, 6, 1);
  String selectedInterval = '30'; // Domyślny interwał
  List<String> intervals = ['15', '30', '60'];
  Map<String, dynamic>? deviceData;
  bool isLoading = false;
  String? error;

  final List<String> devices = ['01', '02', '03', '04', '05', '06', '07'];

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
      final responses = await Future.wait(
        devices.map(
          (deviceId) => http.get(
            Uri.parse(
              'http://localhost:8080/plugs/01/$deviceId?interval=$selectedInterval',
            ),
          ),
        ),
      );

      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate);
      final Map<String, Map<String, dynamic>> fetchedData = {};

      for (var i = 0; i < devices.length; i++) {
        final deviceId = devices[i];
        final response = responses[i];

        print('Response status for device $deviceId: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final List<dynamic> decodedBody = json.decode(response.body);
            print('Response body for device $deviceId: $decodedBody');

            final deviceDataForDate = decodedBody.firstWhere(
              (item) =>
                  item['device'] == deviceId && item['date'] == formattedDate,
              orElse: () => null,
            );

            if (deviceDataForDate != null) {
              fetchedData[deviceId] = deviceDataForDate;
            } else {
              fetchedData[deviceId] = {'data': []};
            }
          } catch (e) {
            print('Error parsing data for device $deviceId: $e');
            fetchedData[deviceId] = {'data': []};
          }
        } else {
          print(
            'Failed to fetch data for device $deviceId. Status code: ${response.statusCode}',
          );
          fetchedData[deviceId] = {'data': []};
        }
      }

      setState(() {
        deviceData = fetchedData;
      });
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

  List<FlSpot> _buildSpots(Map<String, dynamic> data) {
    final List dataPoints = data['data'] ?? [];
    if (dataPoints.isEmpty) {
      print('No data for device ${data['device']} on selected date');
      return [];
    }

    return List.generate(dataPoints.length, (index) {
      final point = dataPoints[index];
      return FlSpot(index.toDouble(), (point['value'] as num).toDouble());
    });
  }

  double _getMinY(Map<String, dynamic> data) {
    final dataPoints = data['data'] ?? [];
    if (dataPoints.isEmpty) return 0;
    double minValue = double.infinity;
    for (var point in dataPoints) {
      double value = (point['value'] as num).toDouble();
      if (value < minValue) minValue = value;
    }
    return minValue - 0.5;
  }

  double _getMaxY(Map<String, dynamic> data) {
    final dataPoints = data['data'] ?? [];
    if (dataPoints.isEmpty) return 1;
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
        title: const Text('🌿 Visualisations of Plugs data'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFd0f0d5), Color(0xFFe9f8ec)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 8,
                    offset: const Offset(2, 2),
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
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Change'),
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
                      const Text('Interval:'),
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
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : deviceData == null || deviceData!.isEmpty
                      ? const Center(child: Text("No data available"))
                      : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final deviceId = devices[index];
                          final data = deviceData![deviceId];

                          if (data == null ||
                              data['data'] == null ||
                              data['data'].isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No data for device $deviceId on $formatted',
                                  ),
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Device $deviceId (${data['description']})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Occupancy data for $formatted, interval: ${data['interval']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: LineChart(
                                        LineChartData(
                                          lineTouchData: LineTouchData(
                                            touchTooltipData: LineTouchTooltipData(
                                              getTooltipItems:
                                                  (spots) =>
                                                      spots.map((spot) {
                                                        final index =
                                                            spot.x.toInt();
                                                        if (data['data'] !=
                                                                null &&
                                                            index <
                                                                data['data']
                                                                    .length) {
                                                          final time =
                                                              data['data'][index]['time'];
                                                          return LineTooltipItem(
                                                            '$time\n${spot.y.toStringAsFixed(1)}',
                                                            const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          );
                                                        }
                                                        return null;
                                                      }).toList(),
                                            ),
                                          ),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                interval:
                                                    (data['data']?.length / 5)
                                                                .floor()
                                                                .toDouble() >
                                                            0
                                                        ? (data['data']
                                                                    ?.length /
                                                                5)
                                                            .floor()
                                                            .toDouble()
                                                        : 1,
                                                getTitlesWidget: (value, _) {
                                                  final index = value.toInt();
                                                  if (data['data'] != null &&
                                                      index <
                                                          data['data'].length) {
                                                    return Text(
                                                      data['data'][index]['time'],
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                interval:
                                                    ((_getMaxY(data) -
                                                                        _getMinY(
                                                                          data,
                                                                        )) /
                                                                    3)
                                                                .ceil()
                                                                .toDouble() >
                                                            0
                                                        ? ((_getMaxY(data) -
                                                                    _getMinY(
                                                                      data,
                                                                    )) /
                                                                3)
                                                            .ceil()
                                                            .toDouble()
                                                        : 1,
                                                getTitlesWidget: (value, _) {
                                                  return Text(
                                                    value.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            horizontalInterval:
                                                ((_getMaxY(data) -
                                                                    _getMinY(
                                                                      data,
                                                                    )) /
                                                                5)
                                                            .ceil()
                                                            .toDouble() >
                                                        0
                                                    ? ((_getMaxY(data) -
                                                                _getMinY(
                                                                  data,
                                                                )) /
                                                            5)
                                                        .ceil()
                                                        .toDouble()
                                                    : 1,
                                            getDrawingHorizontalLine:
                                                (value) => FlLine(
                                                  color: Colors.green.shade200,
                                                  strokeWidth: 1,
                                                ),
                                          ),
                                          borderData: FlBorderData(show: true),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _buildSpots(data),
                                              isCurved: true,
                                              color: const Color.fromARGB(
                                                255,
                                                7,
                                                81,
                                                10,
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: Colors.green.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                              dotData: const FlDotData(
                                                show: false,
                                              ),
                                            ),
                                          ],
                                          minX: 0,
                                          maxX:
                                              (data['data']?.length
                                                      .toDouble() ??
                                                  0) -
                                              1,
                                          minY: _getMinY(data),
                                          maxY: _getMaxY(data),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
