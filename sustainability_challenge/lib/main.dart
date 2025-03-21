import 'package:flutter/material.dart';
import 'data/occupancy_data_loader.dart';
import 'widgets/occupancy_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<double>? summerData;
  List<double>? winterData;

  @override
  void initState() {
    super.initState();

    // Loading data
    Future.wait([
      load15MinAveragedData(
        "assets/data_eth/occupancy/01_occupancy_csv/01_summer.csv",
      ),
      load15MinAveragedData(
        "assets/data_eth/occupancy/01_occupancy_csv/01_winter.csv",
      ),
    ]).then((data) {
      setState(() {
        summerData = data[0]; // Dane letnie
        winterData = data[1]; // Dane zimowe
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Occupancy Visualization")),
        body: Center(
          child:
              (summerData == null || winterData == null)
                  ? CircularProgressIndicator() // Wczytywanie danych
                  : OccupancyChart(
                    summerData: summerData!,
                    winterData: winterData!,
                  ), // Wykres z dwoma zestawami danych
        ),
      ),
    );
  }
}
