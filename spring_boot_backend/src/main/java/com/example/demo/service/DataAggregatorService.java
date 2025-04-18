package com.example.demo.service;

import com.opencsv.CSVReader;
import org.springframework.stereotype.Service;

import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DataAggregatorService {

        public Map<String, List<Map<String, Object>>> aggregateDataEvery15MinutesBySeason(String season)
        {
        List<DataPoint> flatData = new ArrayList<>();

        String filename = switch (season.toLowerCase()) {
        case "summer" -> "/01_summer.csv";
        case "winter" -> "/01_winter.csv";
        default -> throw new IllegalArgumentException("Invalid season: " + season);
        };


        try (CSVReader reader = new CSVReader(
        new InputStreamReader(getClass().getResourceAsStream(filename)))) {

        String[] headers = reader.readNext(); // skip the first row with time headers
        String[] row;
        DateTimeFormatter inputFormat = DateTimeFormatter.ofPattern("dd-MMM-yyyy", Locale.ENGLISH);

        while ((row = reader.readNext()) != null) {
        LocalDate date = LocalDate.parse(row[0], inputFormat);

        int intervalCount = 0;

        for (int i = 1; i < row.length; i += 900) {
            int sum = 0;
            int count = 0;

            for (int j = i; j < i + 900 && j < row.length; j++) {
                sum += Integer.parseInt(row[j].trim());
                count++;
            }

            double average = count > 0 ? (double) sum / count : 0;

            // Compute the corresponding 15-minute timestamp
            int totalMinutes = intervalCount * 15;
            int hour = totalMinutes / 60;
            int minute = totalMinutes % 60;

            LocalTime time = LocalTime.of(hour, minute);
            flatData.add(new DataPoint(date, time, (int) average));

            intervalCount++;
        }
        }
        } catch (Exception e) {
        e.printStackTrace();
        }

        return flatData.stream()
        .collect(Collectors.groupingBy(
        dp -> dp.date.toString(),
        Collectors.collectingAndThen(
            Collectors.groupingBy(dp -> dp.time, TreeMap::new, Collectors.averagingInt(dp -> dp.value)),
            grouped -> grouped.entrySet().stream().map(entry -> {
                Map<String, Object> intervalData = new HashMap<>();
                intervalData.put("time", entry.getKey().toString());
                intervalData.put("value", entry.getValue());
                return intervalData;
            }).collect(Collectors.toList())
        )
        ));
        }


    // Helper class
    static class DataPoint {
        LocalDate date;
        LocalTime time;
        int value;

        DataPoint(LocalDate date, LocalTime time, int value) {
            this.date = date;
            this.time = time;
            this.value = value;
        }
    }
}
