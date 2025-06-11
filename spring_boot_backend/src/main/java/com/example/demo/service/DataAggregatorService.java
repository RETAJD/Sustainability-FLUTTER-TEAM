package com.example.demo.service;

import com.opencsv.CSVReader;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DataAggregatorService {

    @Cacheable(value = "seasonCache", key = "#season + '-' + #interval")
    public List<Map<String, Object>> aggregateDataEvery15MinutesBySeason(String season, int interval) {
        String filename = switch (season.toLowerCase()) {
            case "summer" -> "/01_summer.csv";
            case "winter" -> "/01_winter.csv";
            default -> throw new IllegalArgumentException("Invalid season: " + season);
        };

        List<DataPoint> flatData = new ArrayList<>();

        try (
            BufferedReader reader = new BufferedReader(new InputStreamReader(getClass().getResourceAsStream(filename)));
            CSVReader csvReader = new CSVReader(reader)
        ) {
            csvReader.readNext(); // Skip header
            String[] row;
            DateTimeFormatter inputFormat = DateTimeFormatter.ofPattern("dd-MMM-yyyy", Locale.ENGLISH);

            while ((row = csvReader.readNext()) != null) {
                LocalDate date = LocalDate.parse(row[0].trim(), inputFormat);
                int intervalSize = interval * 60;
                int intervalCount = 0;

                for (int i = 1; i < row.length; i += intervalSize) {
                    int sum = 0, count = 0;
                    for (int j = i; j < i + intervalSize && j < row.length; j++) {
                        sum += Integer.parseInt(row[j].trim());
                        count++;
                    }

                    double average = count > 0 ? (double) sum / count : 0;
                    int totalMinutes = intervalCount * interval;
                    LocalTime time = LocalTime.of(totalMinutes / 60, totalMinutes % 60);
                    flatData.add(new DataPoint(date, time, average));
                    intervalCount++;
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return flatData.stream()
            .collect(Collectors.groupingBy(dp -> dp.date, TreeMap::new, Collectors.toList()))
            .entrySet()
            .stream()
            .map(entry -> {
                String formattedDate = entry.getKey().format(DateTimeFormatter.ofPattern("dd-MMM-yyyy", Locale.ENGLISH));
                List<Map<String, Object>> data = entry.getValue().stream()
                    .collect(Collectors.groupingBy(dp -> dp.time, TreeMap::new, Collectors.averagingDouble(dp -> dp.value)))
                    .entrySet()
                    .stream()
                    .map(e -> {
                        Map<String, Object> map = new LinkedHashMap<>();
                        map.put("time", e.getKey().toString());
                        map.put("value", e.getValue());
                        return map;
                    })
                    .collect(Collectors.toList());

                Map<String, Object> result = new LinkedHashMap<>();
                result.put("date", formattedDate);
                result.put("interval", interval + "min");
                result.put("data", data);
                return result;


            })
            .collect(Collectors.toList());
    }

    static class DataPoint {
        LocalDate date;
        LocalTime time;
        double value;

        DataPoint(LocalDate date, LocalTime time, double value) {
            this.date = date;
            this.time = time;
            this.value = value;
        }
    }
}
