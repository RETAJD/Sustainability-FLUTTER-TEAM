import 'package:flutter/material.dart';
import 'package:sustainability_challenge/data/occupancy_data_loader.dart';
import 'package:sustainability_challenge/widgets/occupancy_chart.dart';

class OccupancyScreen extends StatefulWidget {
  @override
  _OccupancyScreenState createState() => _OccupancyScreenState();
}

class _OccupancyScreenState extends State<OccupancyScreen> {
  List<double>? summerData;
  List<double>? winterData;

  @override
  void initState() {
    super.initState();
    Future.wait([
      load15MinAveragedData(
        "assets/data_eth/occupancy/01_occupancy_csv/01_summer.csv",
      ),
      load15MinAveragedData(
        "assets/data_eth/occupancy/01_occupancy_csv/01_winter.csv",
      ),
    ]).then((data) {
      setState(() {
        summerData = data[0];
        winterData = data[1];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Occupancy Data"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Center(
        child:
            (summerData == null || winterData == null)
                ? CircularProgressIndicator()
                : OccupancyChart(
                  summerData: summerData!,
                  winterData: winterData!,
                ),
      ),
    );
  }
}
