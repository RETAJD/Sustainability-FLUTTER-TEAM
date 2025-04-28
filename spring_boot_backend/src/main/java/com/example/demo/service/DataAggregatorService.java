package com.example.demo.service;

import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.opencsv.CSVReader;

@Service
public class DataAggregatorService {

    public Map<String, Double> getWeeklyAverages() {
        List<DataPoint> flatData = new ArrayList<>();

        try (CSVReader reader = new CSVReader(
                new InputStreamReader(getClass().getResourceAsStream("/01_summer.csv")))) {

            String[] headers = reader.readNext(); // first row = times
    String[] row;

            DateTimeFormatter inputFormat = DateTimeFormatter.ofPattern("dd-MMM-yyyy", Locale.ENGLISH);

            while ((row = reader.readNext()) != null) {
                LocalDate date = LocalDate.parse(row[0], inputFormat);
                for (int i = 1; i < row.length; i++) {
                    int value = Integer.parseInt(row[i].trim());
                    flatData.add(new DataPoint(date, headers[i].replace("'", ""), value));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Group by year+week and average
        return flatData.stream().collect(Collectors.groupingBy(
                dp -> dp.date.toString(), // Format: yyyy-MM-dd
                Collectors.averagingInt(dp -> dp.value)
        ));

    }

    // Helper class
    static class DataPoint {

        LocalDate date;
        String time;
        int value;

        DataPoint(LocalDate date, String time, int value) {
            this.date = date;
            this.time = time;
            this.value = value;
        }
    }
}
