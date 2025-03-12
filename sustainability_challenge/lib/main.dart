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
  List<double>? occupancyData;

  @override
  void initState() {
    super.initState();
    loadOccupancyData(
      "assets/data_eth/occupancy/01_occupancy_csv/01_summer.csv",
    ).then((data) {
      setState(() {
        occupancyData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Occupancy noora")),
        body: Center(
          child:
              occupancyData == null
                  ? CircularProgressIndicator() // Wczytywanie
                  : OccupancyChart(data: occupancyData!),
        ),
      ),
    );
  }
}
