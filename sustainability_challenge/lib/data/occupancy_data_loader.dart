import 'dart:convert';
import 'package:flutter/services.dart';

// loading and transform occupancy data
Future<List<double>> loadOccupancyData(String path) async {
  final String rawData = await rootBundle.loadString(path);
  final List<String> rows = LineSplitter.split(rawData).toList();

  List<double> occupancyPerMinute = [];

  for (String row in rows.skip(1)) {
    // skip header
    List<String> values = row.split(',');
    List<int> secondData =
        values.skip(1).map((e) => int.tryParse(e) ?? 0).toList();

    // transfrom 86400 seconds to 1440 minutes (aver from 60 values)
    for (int i = 0; i < secondData.length; i += 60) {
      double avg = secondData.sublist(i, i + 60).reduce((a, b) => a + b) / 60;
      occupancyPerMinute.add(avg);
    }
  }

  return occupancyPerMinute;
}
