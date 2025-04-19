import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

const String _baseUrlPlugs = 'http://127.0.0.1:8000/plugs/01/';
const String _baseUrlSmartMeter = 'http://localhost:8000/smartmeter';

class DevicesScreenSecond extends StatefulWidget {
  @override
  _DevicesScreenCombinedState createState() => _DevicesScreenCombinedState();
}

class _DevicesScreenCombinedState extends State<DevicesScreenSecond> {
  DateTime selectedDate = DateTime(2012, 9, 15);
  String selectedInterval = '30'; // Default interval for plugs
  List<String> intervalsPlugs = ['15', '30', '60'];
  Map<String, dynamic>? allDevicesData;
  bool isLoadingPlugs = false;
  String? errorPlugs;
  Map<String, bool> deviceVisibility = {};
  final List<Map<String, String>> devicesData = [
    {'id': '01', 'name': 'Fridge', 'icon': 'kitchen'},
    {'id': '02', 'name': 'Dryer', 'icon': 'local_laundry_service'},
    {'id': '03', 'name': 'Coffee Maker', 'icon': 'local_cafe'},
    {'id': '04', 'name': 'Kettle', 'icon': 'free_breakfast'},
    {'id': '05', 'name': 'Washing Machine', 'icon': 'wash'},
    {'id': '06', 'name': 'Computer (with router)', 'icon': 'computer'},
    {'id': '07', 'name': 'Freezer', 'icon': 'ac_unit'},
  ];
  final Map<String, IconData> deviceIcons = {
    'kitchen': Icons.kitchen,
    'local_laundry_service': Icons.local_laundry_service,
    'local_cafe': Icons.local_cafe,
    'free_breakfast': Icons.free_breakfast,
    'wash': Icons.wash,
    'computer': Icons.computer,
    'ac_unit': Icons.ac_unit,
  };
  final List<Color> deviceColors = [
    Colors.blue,
    Colors.red,
    Colors.black,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
  ];

  // Smart Meter Data
  Map<String, dynamic>? smartMeterData;
  bool isLoadingSmartMeter = false;
  String? errorSmartMeter;
  double? totalEnergyKWh;
  double? totalCO2EmissionsG;
  double? emissionReductionG;
  List<FlSpot> co2EmissionSpots = [];
  double? co2EmissionPerSecondG;

  double calculateCO2Emission(double energyKWh) {
    const double emissionFactor =
        0.652; // kg CO₂ na kWh (przykład - ZAKTUALIZUJ!)
    return energyKWh * emissionFactor;
  }

  @override
  void initState() {
    super.initState();
    for (var device in devicesData) {
      deviceVisibility[device['id']!] = true;
    }
    fetchPlugsData();
    fetchSmartMeterData();
  }

  Future<void> fetchPlugsData() async {
    setState(() {
      isLoadingPlugs = true;
      errorPlugs = null;
      allDevicesData = {};
    });
    try {
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate);
      for (var device in devicesData) {
        final deviceId = device['id']!;
        final String apiUrl =
            '$_baseUrlPlugs$deviceId?interval=$selectedInterval';
        final Uri url = Uri.parse(apiUrl);
        print('Fetching plugs data for device $deviceId at: $url');
        final response = await http.get(url);
        print('Response status for device $deviceId: ${response.statusCode}');
        if (response.statusCode == 200) {
          try {
            final List<dynamic> decodedBody = json.decode(response.body);
            final deviceDataForDate = decodedBody.firstWhere(
              (item) =>
                  item['device'] == deviceId && item['date'] == formattedDate,
              orElse: () => null,
            );
            allDevicesData![deviceId] = deviceDataForDate;
          } catch (e) {
            print(
              'Error parsing JSON for device $deviceId: $e\nResponse body: ${response.body}',
            );
            allDevicesData![deviceId] = {'data': []};
          }
        } else {
          print(
            'Failed to fetch plugs data for device $deviceId. Status code: ${response.statusCode}\nURL: $url',
          );
          allDevicesData![deviceId] = {'data': []};
        }
      }
      setState(() {});
    } catch (e) {
      setState(() {
        errorPlugs = 'Connection error occurred: $e';
      });
    } finally {
      setState(() {
        isLoadingPlugs = false;
      });
    }
  }

  Future<void> fetchSmartMeterData() async {
    setState(() {
      isLoadingSmartMeter = true;
      errorSmartMeter = null;
      smartMeterData = null;
      totalEnergyKWh = null;
      totalCO2EmissionsG = null;
      emissionReductionG = null;
      co2EmissionSpots = [];
      co2EmissionPerSecondG = null;
    });
    try {
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate);
      // Używamy stałej wartości '15' dla interwału smartmetru
      final String apiUrl =
          '$_baseUrlSmartMeter/powerallphases?interval=$selectedInterval';
      final Uri url = Uri.parse(apiUrl);
      print('Fetching smart meter data at: $url');
      final response = await http.get(url);
      print('Smart meter response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          final List<dynamic> decodedBody = json.decode(response.body);
          final dailyData = decodedBody.firstWhere(
            (item) => item['date'] == formattedDate,
            orElse: () => null,
          );
          if (dailyData != null && dailyData['data'] != null) {
            smartMeterData = dailyData;
            _calculateEnergyAndCO2(dailyData['data']);
          } else {
            smartMeterData = {'data': []};
            totalEnergyKWh = 0;
            totalCO2EmissionsG = 0;
            emissionReductionG = 0;
            co2EmissionSpots = [];
            co2EmissionPerSecondG = 0;
          }
        } catch (e) {
          print(
            'Error parsing JSON for smart meter data: $e\nResponse body: ${response.body}',
          );
          setState(() {
            errorSmartMeter = 'Error parsing smart meter data.';
          });
        }
      } else {
        setState(() {
          errorSmartMeter =
              'Failed to fetch smart meter data. Status code: ${response.statusCode}\nURL: $url';
        });
      }
    } catch (e) {
      setState(() {
        errorSmartMeter =
            'Connection error occurred while fetching smart meter data: $e';
      });
    } finally {
      setState(() {
        isLoadingSmartMeter = false;
      });
    }
  }

  void _calculateEnergyAndCO2(List<dynamic> dataPoints) {
    if (dataPoints.isEmpty) {
      totalEnergyKWh = 0;
      totalCO2EmissionsG = 0;
      emissionReductionG = 0;
      co2EmissionSpots = [];
      co2EmissionPerSecondG = 0;
      return;
    }

    double totalEnergyWh = 0;
    double previousPowerW = dataPoints.first['value'] as double;
    DateTime? previousTime;

    List<FlSpot> spots = [];

    for (var i = 0; i < dataPoints.length; i++) {
      final currentPoint = dataPoints[i];
      final currentTimeStr = currentPoint['time'];
      final currentPowerW = currentPoint['value'] as double;

      final currentTime = DateFormat('HH:mm').parse(currentTimeStr);
      if (previousTime != null) {
        final duration = currentTime.difference(previousTime).inSeconds;
        final averagePowerW = (previousPowerW + currentPowerW) / 2;
        final energyWh = averagePowerW * duration / 3600;
        totalEnergyWh += energyWh;

        final co2EmissionG = (energyWh / 1000) * 0.652 * 1000;
        spots.add(FlSpot(i.toDouble(), co2EmissionG));
      }
      previousPowerW = currentPowerW;
      previousTime = currentTime;
    }

    totalEnergyKWh = totalEnergyWh / 1000;
    totalCO2EmissionsG = totalEnergyKWh! * 0.652 * 1000;

    final totalSeconds = dataPoints.length * 15 * 60;
    final energy1100WKh = (1100 * totalSeconds) / 3600 / 1000;
    final co2Emissions1100WG = energy1100WKh * 0.652 * 1000;
    emissionReductionG = co2Emissions1100WG - totalCO2EmissionsG!;

    if (dataPoints.isNotEmpty) {
      co2EmissionPerSecondG =
          (dataPoints.last['value'] as double) / 1000 * 0.652 * 1000 / 3600;
    } else {
      co2EmissionPerSecondG = 0;
    }

    co2EmissionSpots = spots;
    setState(() {});
  }

  List<FlSpot> _buildSpots(Map<String, dynamic>? data) {
    if (data == null || data['data'] == null || data['data'].isEmpty) {
      return [];
    }
    return (data['data'] as List).asMap().entries.map((entry) {
      int index = entry.key;
      var point = entry.value;
      return FlSpot(index.toDouble(), (point['value'] as num).toDouble());
    }).toList();
  }

  double _getMinY() {
    if (allDevicesData == null || allDevicesData!.isEmpty) return 0;
    double minY = double.infinity;
    allDevicesData!.forEach((key, data) {
      if (deviceVisibility[key] == true && data?['data'] != null) {
        for (var point in (data['data'] as List)) {
          double value = (point['value'] as num).toDouble();
          if (value < minY) minY = value;
        }
      }
    });
    return minY == double.infinity ? 0 : minY - 0.5;
  }

  double _getMaxY() {
    if (allDevicesData == null || allDevicesData!.isEmpty) return 1;
    double maxY = double.negativeInfinity;
    allDevicesData!.forEach((key, data) {
      if (deviceVisibility[key] == true && data?['data'] != null) {
        for (var point in (data['data'] as List)) {
          double value = (point['value'] as num).toDouble();
          if (value > maxY) maxY = value;
        }
      }
    });
    return maxY == double.negativeInfinity ? 1 : maxY + 0.5;
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
      fetchPlugsData();
      fetchSmartMeterData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy').format(selectedDate);
    return Scaffold(
      backgroundColor: const Color(0xFFf0f9f2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3f9d5e),
        title: const Text('🌿 Plug & Smart Meter Data'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateIntervalPanel(context, formatted),
              const SizedBox(height: 30),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Electricity Consumption of Plugs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data for $formatted, interval: $selectedInterval min',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 300,
                        child: _buildCombinedChartWithLegend(),
                      ),
                      const SizedBox(height: 16),
                      _buildDeviceVisibilityChips(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Meter Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      isLoadingSmartMeter
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          )
                          : errorSmartMeter != null
                          ? Text(
                            errorSmartMeter!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : smartMeterData == null ||
                              smartMeterData!['data'] == null ||
                              smartMeterData!['data'].isEmpty
                          ? const Text(
                            'No smart meter data available for this date.',
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Energy used: ${totalEnergyKWh?.toStringAsFixed(5)} kWh',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Carbon Footprint: ~${totalCO2EmissionsG?.toStringAsFixed(2)} g CO₂',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Emission Reduction (vs. 1100 W): ~${emissionReductionG?.toStringAsFixed(2)} g CO₂',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'CO₂ Emission Over Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child:
                                    co2EmissionSpots.isNotEmpty
                                        ? LineChart(
                                          LineChartData(
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: co2EmissionSpots,
                                                isCurved: true,
                                                color: Colors.redAccent,
                                                barWidth: 2,
                                                dotData: const FlDotData(
                                                  show: false,
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: false,
                                                ),
                                              ),
                                            ],
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (
                                                    value,
                                                    meta,
                                                  ) {
                                                    final index = value.toInt();
                                                    if (smartMeterData?['data'] !=
                                                            null &&
                                                        index %
                                                                (smartMeterData!['data']
                                                                            .length ~/
                                                                        5 +
                                                                    1) ==
                                                            0 &&
                                                        index <
                                                            smartMeterData!['data']
                                                                .length) {
                                                      return Text(
                                                        smartMeterData!['data'][index]['time'],
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
                                                  getTitlesWidget: (
                                                    value,
                                                    meta,
                                                  ) {
                                                    return Text(
                                                      value.toStringAsFixed(1),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              topTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: false,
                                                ),
                                              ),
                                              rightTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: false,
                                                ),
                                              ),
                                            ),
                                            gridData: const FlGridData(
                                              show: true,
                                            ),
                                            borderData: FlBorderData(
                                              show: true,
                                            ),
                                          ),
                                        )
                                        : const Center(
                                          child: Text(
                                            'No CO₂ emission data available.',
                                          ),
                                        ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CO₂ emission $selectedInterval minutes after $selectedInterval minutes based on smart meter (powerallphases): ~${co2EmissionPerSecondG?.toStringAsFixed(3)} g',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateIntervalPanel(BuildContext context, String formattedDate) {
    return Container(
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
              Icon(Icons.calendar_today, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text('Date: $formattedDate'),
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
              Icon(Icons.timer_outlined, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Interval (Plugs):'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedInterval,
                borderRadius: BorderRadius.circular(10),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.green[800],
                items:
                    intervalsPlugs.map((e) {
                      return DropdownMenuItem(value: e, child: Text('$e min'));
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedInterval = value;
                    });
                    fetchPlugsData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedChartWithLegend() {
    return Row(
      children: [
        Expanded(
          child:
              isLoadingPlugs
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                  : errorPlugs != null
                  ? Center(
                    child: Text(
                      errorPlugs!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                  : allDevicesData == null || allDevicesData!.isEmpty
                  ? const Center(child: Text("No plug data available"))
                  : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              if (touchedSpot == null) {
                                return null;
                              }
                              final deviceId =
                                  devicesData[touchedSpot.barIndex]['id']!;
                              final deviceName =
                                  devicesData[touchedSpot.barIndex]['name']!;
                              final data = allDevicesData![deviceId];
                              final index = touchedSpot.x.toInt();
                              if (data != null &&
                                  data['data'] != null &&
                                  index < data['data'].length) {
                                final time = data['data'][index]['time'];
                                final value = touchedSpot.y.toStringAsFixed(1);
                                final color =
                                    deviceColors[touchedSpot.barIndex %
                                        deviceColors.length];
                                return LineTooltipItem(
                                  '$deviceName\nTime: $time, Value: $value',
                                  TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval:
                                (allDevicesData
                                                    ?.values
                                                    .firstOrNull?['data']
                                                    ?.length /
                                                5)
                                            .floor()
                                            .toDouble() >
                                        0
                                    ? (allDevicesData
                                                ?.values
                                                .firstOrNull?['data']
                                                ?.length /
                                            5)
                                        .floor()
                                        .toDouble()
                                    : 1,
                            getTitlesWidget: (value, _) {
                              final data =
                                  allDevicesData?.values.firstOrNull?['data'];
                              final index = value.toInt();
                              if (data != null && index < data.length) {
                                return Text(
                                  data[index]['time'],
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
                                ((_getMaxY() - _getMinY()) / 3)
                                            .ceil()
                                            .toDouble() >
                                        0
                                    ? ((_getMaxY() - _getMinY()) / 3)
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
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval:
                            ((_getMaxY() - _getMinY()) / 5).ceil().toDouble() >
                                    0
                                ? ((_getMaxY() - _getMinY()) / 5)
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
                      lineBarsData:
                          devicesData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final device = entry.value;
                            final deviceId = device['id']!;
                            final data = allDevicesData![deviceId];
                            final isVisible =
                                deviceVisibility[deviceId] ?? true;
                            final color =
                                deviceColors[index % deviceColors.length];
                            return isVisible
                                ? LineChartBarData(
                                  spots: _buildSpots(data),
                                  isCurved: true,
                                  color: color,
                                  belowBarData: BarAreaData(show: false),
                                  dotData: const FlDotData(show: false),
                                )
                                : LineChartBarData(show: false, spots: []);
                          }).toList(),
                      minX: 0,
                      maxX:
                          (allDevicesData?.values.firstOrNull?['data']?.length
                                  .toDouble() ??
                              0) -
                          1,
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                    ),
                  ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: ListView.builder(
            itemCount: devicesData.length,
            itemBuilder: (context, index) {
              final device = devicesData[index];
              final deviceId = device['id']!;
              final deviceName = device['name']!;
              final deviceIconName = device['icon']!;
              final deviceIcon = deviceIcons[deviceIconName] ?? Icons.power;
              final isVisible = deviceVisibility[deviceId] ?? true;
              final color = deviceColors[index % deviceColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      deviceVisibility[deviceId] = !isVisible;
                    });
                  },
                  child: Opacity(
                    opacity: isVisible ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Icon(deviceIcon, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deviceName,
                            style: TextStyle(fontSize: 14, color: color),
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
    );
  }

  Widget _buildDeviceVisibilityChips() {
    return Wrap(
      spacing: 8.0,
      children:
          devicesData.asMap().entries.map((entry) {
            final index = entry.key;
            final device = entry.value;
            final deviceId = device['id']!;
            final deviceName = device['name']!;
            final color = deviceColors[index % deviceColors.length];
            final isVisible = deviceVisibility[deviceId] ?? true;
            return GestureDetector(
              onTap: () {
                setState(() {
                  deviceVisibility[deviceId] = !isVisible;
                });
              },
              child: Chip(
                label: Text(
                  deviceName,
                  style: TextStyle(
                    color: isVisible ? Colors.black : Colors.grey,
                  ),
                ),
                backgroundColor: color.withOpacity(0.3),
                side: BorderSide(color: isVisible ? color : Colors.grey),
              ),
            );
          }).toList(),
    );
  }
}
