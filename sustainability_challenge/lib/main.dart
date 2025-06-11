import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sustainability_challenge/screens/plugs_screen.dart';
import 'package:sustainability_challenge/screens/screen_occupancy.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sustainability_challenge/widgets/occupancy_chart_days.dart';
import 'package:sustainability_challenge/widgets/plugs_chart_days.dart';
import 'package:sustainability_challenge/widgets/second_page.dart';
import 'package:sustainability_challenge/widgets/smartdata_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationSidebar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(),
                    SizedBox(height: 20),
                    NotificationCard(),
                    SizedBox(height: 20),
                    SpecificPowerChart(), // Zamiast OverviewChart
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: DeviceStatusCards()),
                        SizedBox(width: 20),
                        Expanded(child: EnergyPieChart()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecificPowerChart extends StatefulWidget {
  @override
  _SpecificPowerChartState createState() => _SpecificPowerChartState();
}

class _SpecificPowerChartState extends State<SpecificPowerChart> {
  Map<String, dynamic>? powerData;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchPowerData();
  }

  Future<void> fetchPowerData() async {
    setState(() {
      isLoading = true;
      error = null;
      powerData = null;
    });

    final date = DateTime(2013, 1, 23);
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final interval = '15';
    final url =
        'http://localhost:8080/smartmeter/powerallphases?interval=$interval';

    try {
      final response = await http.get(Uri.parse(url));
      print(response.statusCode);
      if (response.statusCode == 200) {
        try {
          final List<dynamic> decodedBody = json.decode(response.body);
          final dataForDate = decodedBody.firstWhere(
            (item) => item['date'] == formattedDate,
            orElse: () => null,
          );

          if (dataForDate != null) {
            setState(() {
              powerData = dataForDate;
            });
          } else {
            setState(() {
              error = 'No data found for $formattedDate';
            });
          }
        } catch (e) {
          setState(() {
            error = 'Error parsing data: $e';
          });
        }
      } else {
        setState(() {
          error = 'Failed to fetch data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = '$e';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power Consumption (23 Jan 2013, 15 min interval)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 200,
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(child: Text(error!))
                    : powerData == null ||
                        powerData!['data'] == null ||
                        powerData!['data'].isEmpty
                    ? Center(child: Text('No data available'))
                    : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems:
                                (spots) =>
                                    spots.map((spot) {
                                      final index = spot.x.toInt();
                                      if (powerData != null &&
                                          powerData!['data'] != null &&
                                          index < powerData!['data'].length) {
                                        final time =
                                            powerData!['data'][index]['time'];
                                        return LineTooltipItem(
                                          '<span class="math-inline">time\\n</span>{spot.y.toStringAsFixed(1)}',
                                          const TextStyle(color: Colors.white),
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
                                  (powerData!['data']?.length / 5)
                                              .floor()
                                              .toDouble() >
                                          0
                                      ? (powerData!['data']?.length / 5)
                                          .floor()
                                          .toDouble()
                                      : 1,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (powerData != null &&
                                    powerData!['data'] != null &&
                                    index < powerData!['data'].length) {
                                  return Text(
                                    powerData!['data'][index]['time'],
                                    style: const TextStyle(fontSize: 10),
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
                                  ((_getMaxY(powerData ?? {'data': []}) -
                                                      _getMinY(
                                                        powerData ??
                                                            {'data': []},
                                                      )) /
                                                  3)
                                              .ceil()
                                              .toDouble() >
                                          0
                                      ? ((_getMaxY(powerData ?? {'data': []}) -
                                                  _getMinY(
                                                    powerData ?? {'data': []},
                                                  )) /
                                              3)
                                          .ceil()
                                          .toDouble()
                                      : 1,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  value.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval:
                              ((_getMaxY(powerData ?? {'data': []}) -
                                                  _getMinY(
                                                    powerData ?? {'data': []},
                                                  )) /
                                              5)
                                          .ceil()
                                          .toDouble() >
                                      0
                                  ? ((_getMaxY(powerData ?? {'data': []}) -
                                              _getMinY(
                                                powerData ?? {'data': []},
                                              )) /
                                          5)
                                      .ceil()
                                      .toDouble()
                                  : 1,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildSpots(powerData ?? {'data': []}),
                            isCurved: true,
                            color: Colors.green.shade700,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.3),
                            ),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        minX: 0,
                        maxX: (powerData?['data']?.length.toDouble() ?? 0) - 1,
                        minY: _getMinY(powerData ?? {'data': []}),
                        maxY: _getMaxY(powerData ?? {'data': []}),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class NavigationSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.green.shade600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.power, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DevicesScreen()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.sensors, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OccupancyScreenNew()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.white), // Zmieniona ikona
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SmartMeterScreen()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.white), // Zmieniona ikona
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DevicesScreenSecond()),
                ),
          ),
        ],
      ),
    );
  }
}

class GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, Rosa! 👋",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                "Here is your home today\n${DateTime.now().toString().substring(0, 16)}",
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, color: Colors.orange, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Update",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "☕ Coffee machine consuming power while you're away!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  "We've noticed your coffee machine is using electricity even though you're not home. "
                  "Unplugging devices when they're not in use can save energy and reduce your bills.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusCards extends StatefulWidget {
  @override
  _DeviceStatusCardsState createState() => _DeviceStatusCardsState();
}

class _DeviceStatusCardsState extends State<DeviceStatusCards> {
  List<Map<String, dynamic>> devices = [
    {'name': 'Fridge', 'status': true},
    {'name': 'Freezer', 'status': true},
    {'name': 'Coffee Machine', 'status': true},
    {'name': 'PC', 'status': false},
    {'name': 'Kettle', 'status': true},
    {'name': 'Washing Machine', 'status': false},
    {'name': 'Dryer', 'status': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(devices.length, (index) {
        final device = devices[index];
        return Container(
          width: 120,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                device['status'] ? Colors.green.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices_other, size: 32, color: Colors.green.shade700),
              SizedBox(height: 8),
              Text(
                device['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: device['status'],
                onChanged: (bool value) {
                  setState(() {
                    devices[index]['status'] = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class EnergyPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: 15.1,
        color: Colors.green,
        title: '15% Fridge',
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 13.3,
        color: Colors.lightGreen.shade700,
        title: '13% Freezer',
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 3.88,
        color: Colors.greenAccent.shade400,
        title: '4% Coffee',
        titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 4.3,
        color: Colors.teal.shade400,
        title: '4% Kettle',
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 17.3,
        color: Colors.lime.shade600,
        title: '17% Washer',
        titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 16.5,
        color: Colors.lightGreenAccent.shade700,
        title: '16% Dryer',
        titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        radius: 60,
      ),
      PieChartSectionData(
        value: 12.8,
        color: Colors.tealAccent.shade700,
        title: '13% PC',
        titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        radius: 60,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Electricity Consumed per Device',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
