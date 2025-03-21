import 'dart:convert';
import 'package:flutter/services.dart';

// loading and transform occupancy data
Future<List<double>> load15MinAveragedData(String path) async {
  final String rawData = await rootBundle.loadString(path);
  final List<String> rows = LineSplitter.split(rawData).toList();

  List<double> averagedData = List.filled(96, 0.0); // 96  (15 min × 24h)
  List<int> countPerInterval = List.filled(96, 0);

  for (String row in rows.skip(1)) {
    // ship header
    List<String> values = row.split(',');
    List<int> secondData =
        values.skip(1).map((e) => int.tryParse(e) ?? 0).toList();

    // Grouping 15 minutes (900 seconds)
    for (int i = 0; i < secondData.length; i += 900) {
      int index = i ~/ 900; // indexes in 96 elements table
      if (i + 900 <= secondData.length) {
        double avg =
            secondData.sublist(i, i + 900).reduce((a, b) => a + b) / 900;
        averagedData[index] += avg;
        countPerInterval[index]++;
      }
    }
  }

  // final generalistation
  for (int i = 0; i < averagedData.length; i++) {
    if (countPerInterval[i] > 0) {
      averagedData[i] /= countPerInterval[i];
    }
  }

  return averagedData;
}
