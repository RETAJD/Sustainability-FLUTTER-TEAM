import 'package:flutter/material.dart';
import 'package:sustainability_challenge/data/plugs_data_loader.dart';
import 'package:sustainability_challenge/widgets/plugs_chart.dart';

class PlugsScreen extends StatefulWidget {
  @override
  _PlugsScreenState createState() => _PlugsScreenState();
}

class _PlugsScreenState extends State<PlugsScreen> {
  List<double> plugsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlugsData();
  }

  Future<void> loadPlugsData() async {
    final data = await loadDeviceData('assets/data_eth/plugs/01_plugs_csv/');

    // Zamiast ładować tylko pierwsze 1000 danych, agregujemy je do 500 punktów
    final aggregatedData = aggregateData(
      data,
      500,
    ); // Agregujemy do 500 punktów

    setState(() {
      plugsData = aggregatedData;
      isLoading = false;
    });
  }

  // Funkcja do agregowania danych na 500 punktów
  List<double> aggregateData(List<double> data, int numPoints) {
    final int chunkSize =
        (data.length / numPoints).ceil(); // Ile punktów w jednej grupie
    List<double> aggregatedData = [];

    for (int i = 0; i < numPoints; i++) {
      // Obliczanie średniej dla każdej grupy punktów
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : plugsData.isEmpty
              ? Center(child: Text("Brak danych do wyświetlenia"))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 500,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PowerConsumptionChart(deviceData: plugsData),
                      ),
                    ),
                    Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: plugsData.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            'Energy: ${plugsData[index].toStringAsFixed(2)} kWh',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
