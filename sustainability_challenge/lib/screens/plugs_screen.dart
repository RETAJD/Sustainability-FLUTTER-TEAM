import 'package:flutter/material.dart';
import 'package:sustainability_challenge/data/plugs_data_loader.dart';
import 'package:sustainability_challenge/widgets/plugs_chart.dart';

class PlugsScreen extends StatefulWidget {
  @override
  _PlugsScreenState createState() => _PlugsScreenState();
}

class _PlugsScreenState extends State<PlugsScreen> {
  Map<String, List<double>> plugsData = {};
  bool isLoading = true;

  // Opisy urządzeń
  final Map<String, String> deviceDescriptions = {
    '01':
        'Fridge (no. days: 231, coverage: 98.53%)\nMeasurement period: 01.06.12 to 23.01.13',
    '02':
        'Dryer (no. days: 231, coverage: 98.56%)\nMeasurement period: 01.06.12 to 23.01.13',
    '03':
        'Coffee machine (no. days: 113, coverage: 85.36%)\nMeasurement period: 01.06.12 to 23.01.13',
    '04':
        'Kettle (no. days: 203, coverage: 77.65%)\nMeasurement period: 01.06.12 to 23.01.13',
    '05':
        'Washing machine (no. days: 231, coverage: 98.56%)\nMeasurement period: 01.06.12 to 23.01.13',
    '06':
        'PC (no. days: 66, coverage: 84.77%)\nMeasurement period: 01.06.12 to 23.01.13',
    '07':
        'Freezer (no. days: 231, coverage: 98.56%)\nMeasurement period: 01.06.12 to 23.01.13',
  };

  @override
  void initState() {
    super.initState();
    loadPlugsData();
  }

  Future<void> loadPlugsData() async {
    List<String> folders = ['01', '02', '03', '04', '05', '06', '07'];

    for (var folder in folders) {
      final data = await loadDeviceData(
        'assets/data_eth/plugs/01_plugs_csv/$folder/',
      );
      final aggregatedData = aggregateData(data, 500);

      setState(() {
        plugsData[folder] = aggregatedData;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  List<double> aggregateData(List<double> data, int numPoints) {
    final int chunkSize = (data.length / numPoints).ceil();
    List<double> aggregatedData = [];

    for (int i = 0; i < numPoints; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize;
      final chunk = data.sublist(start, end < data.length ? end : data.length);
      final average = chunk.reduce((a, b) => a + b) / chunk.length;
      aggregatedData.add(average);
    }

    return aggregatedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Power Consumption')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : plugsData.isEmpty
              ? Center(child: Text("Brak danych do wyświetlenia"))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children:
                      plugsData.keys.map((folder) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Folder $folder',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                deviceDescriptions[folder] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 500,
                                child: PowerConsumptionChart(
                                  deviceData: plugsData[folder]!,
                                  folderName: folder,
                                ),
                              ),
                              Divider(thickness: 1.5),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
    );
  }
}
