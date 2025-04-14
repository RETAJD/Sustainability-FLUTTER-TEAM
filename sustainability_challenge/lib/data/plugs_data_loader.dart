import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

Future<List<double>> loadDeviceData(String folderPath) async {
  List<double> deviceData = [];

  try {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestData = json.decode(manifestContent);

    final csvFiles =
        manifestData.keys
            .where((key) => key.startsWith(folderPath) && key.endsWith('.csv'))
            .toList();

    if (csvFiles.isEmpty) {
      print("Brak plików CSV w folderze: $folderPath");
      return deviceData; // Zwrócenie pustej listy
    }

    print("Znalezione pliki CSV:");
    csvFiles.forEach((file) {
      print(file); // Logowanie znalezionych plików
    });

    // Ładowanie danych z plików CSV
    for (var path in csvFiles) {
      final fileContent = await rootBundle.loadString(path);
      final rows = const CsvToListConverter(eol: '\n').convert(fileContent);

      for (var row in rows) {
        if (row.isNotEmpty) {
          var val = row[0];
          if (val is double) {
            deviceData.add(val);
          } else if (val is int) {
            deviceData.add(val.toDouble());
          } else if (val is String) {
            final parsed = double.tryParse(val.trim());
            if (parsed != null) {
              deviceData.add(parsed);
            }
          }
        }
      }
    }
  } catch (e) {
    print("Błąd ładowania danych: $e");
  }

  print("Dane urządzenia załadowane: ${deviceData.length} danych");
  return deviceData;
}
