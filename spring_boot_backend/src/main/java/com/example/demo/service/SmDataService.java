package com.example.demo.service;

import org.springframework.stereotype.Service;
import org.springframework.cache.annotation.Cacheable;

import java.io.BufferedReader;
import java.io.File;
import java.nio.file.Files;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SmDataService {

    private static final String BASE_FOLDER = "/01_sm_csv/";

    private static final Map<String, Integer> columnIndexMap = Map.ofEntries(
        Map.entry("powerallphases", 0),
        Map.entry("powerl1", 1),
        Map.entry("powerl2", 2),
        Map.entry("powerl3", 3),
        Map.entry("currentneutral", 4),
        Map.entry("currentl1", 5),
        Map.entry("currentl2", 6),
        Map.entry("currentl3", 7),
        Map.entry("voltagel1", 8),
        Map.entry("voltagel2", 9),
        Map.entry("voltagel3", 10),
        Map.entry("phaseanglevoltagel2l1", 11),
        Map.entry("phaseanglevoltagel3l1", 12),
        Map.entry("phaseanglecurrentvoltagel1", 13),
        Map.entry("phaseanglecurrentvoltagel2", 14),
        Map.entry("phaseanglecurrentvoltagel3", 15)
    );

    private static final Map<String, String> columnDescriptions = Map.ofEntries(
        Map.entry("powerallphases", "Sum of real power over all phases"),
        Map.entry("powerl1", "Real power phase 1"),
        Map.entry("powerl2", "Real power phase 2"),
        Map.entry("powerl3", "Real power phase 3"),
        Map.entry("currentneutral", "Neutral current"),
        Map.entry("currentl1", "Current phase 1"),
        Map.entry("currentl2", "Current phase 2"),
        Map.entry("currentl3", "Current phase 3"),
        Map.entry("voltagel1", "Voltage phase 1"),
        Map.entry("voltagel2", "Voltage phase 2"),
        Map.entry("voltagel3", "Voltage phase 3"),
        Map.entry("phaseanglevoltagel2l1", "Phase shift between voltage on phase 2 and 1"),
        Map.entry("phaseanglevoltagel3l1", "Phase shift between voltage on phase 3 and 1"),
        Map.entry("phaseanglecurrentvoltagel1", "Phase shift between current/voltage on phase 1"),
        Map.entry("phaseanglecurrentvoltagel2", "Phase shift between current/voltage on phase 2"),
        Map.entry("phaseanglecurrentvoltagel3", "Phase shift between current/voltage on phase 3")
    );

    @Cacheable(value = "smartMeterCache", key = "#column + '-' + #interval")
    public List<Map<String, Object>> getAggregatedDataForSm(String column, int interval) {
        try {
            int columnIndex = columnIndexMap.getOrDefault(column, 0);
            String description = columnDescriptions.getOrDefault(column, column);
            File folder = new File(getClass().getResource(BASE_FOLDER).toURI());
            File[] files = folder.listFiles((dir, name) -> name.endsWith(".csv"));

            if (files == null) return Collections.emptyList();

            Arrays.sort(files);

            return Arrays.stream(files)
                .parallel()
                .map(file -> processFile(file, columnIndex, interval, column, description))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    private Map<String, Object> processFile(File file, int columnIndex, int interval, String column, String description) {
        try {
            String date = file.getName().replace(".csv", "");
            List<Double> values = new ArrayList<>();

            try (BufferedReader reader = Files.newBufferedReader(file.toPath())) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (!line.isEmpty()) {
                        int idx = 0, commaCount = 0;
                        for (int i = 0; i < line.length(); i++) {
                            if (line.charAt(i) == ',') {
                                commaCount++;
                                if (commaCount == columnIndex + 1) {
                                    values.add(Double.parseDouble(line.substring(idx, i)));
                                    break;
                                }
                                idx = i + 1;
                            } else if (i == line.length() - 1 && commaCount == columnIndex) {
                                values.add(Double.parseDouble(line.substring(idx)));
                            }
                        }
                    }
                }
            }

            List<Map<String, Object>> intervals = new ArrayList<>();
            int intervalSize = interval * 60;

            for (int i = 0; i < values.size(); i += intervalSize) {
                List<Double> chunk = values.subList(i, Math.min(i + intervalSize, values.size()));
                double avg = chunk.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
                int mins = (i / intervalSize) * interval;
                LocalTime time = LocalTime.of(mins / 60, mins % 60);
                intervals.add(Map.of("time", time.toString().substring(0, 5), "value", avg));
            }

            return Map.of(
                "date", date,
                "interval", interval,
                "data", intervals,
                "column_name", column,
                "description", description
            );

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
