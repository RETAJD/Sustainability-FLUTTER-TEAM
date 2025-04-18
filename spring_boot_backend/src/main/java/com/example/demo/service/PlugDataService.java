package com.example.demo.service;

import org.springframework.stereotype.Service;

import java.io.File;
import java.nio.file.Files;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PlugDataService {

    // Folder path relative to resources
    private static final String BASE_FOLDER = "/01_plugs_csv/";

    // Descriptions for each device ID
    private static final Map<String, String> DEVICE_DESCRIPTIONS = Map.of(
        "01", "Fridge",
        "02", "Dryer",
        "03", "Coffee machine",
        "04", "Kettle",
        "05", "Washing machine",
        "06", "PC",
        "07", "Freezer"
    );

    // Main method to aggregate data for a specific device (e.g., "01")
    public List<Map<String, Object>> getAggregatedDataForDevice(String deviceId) {
        List<Map<String, Object>> results = new ArrayList<>();
        String folderPath = BASE_FOLDER + deviceId; // example: "/01-PLUGS-CSV/01"

        try {
            // Locate the folder using the resource path
            File folder = new File(getClass().getResource(folderPath).toURI());

            // Get all CSV files in that folder
            File[] files = folder.listFiles((dir, name) -> name.endsWith(".csv"));

            if (files != null) {
                Arrays.sort(files); // Optional: sort files by name (so dates are ordered)

                // Process each file (each file = 1 day of 1-second data)
                for (File file : files) {
                    String date = file.getName().replace(".csv", ""); // Get the date from filename

                    // Read all lines, parse each line as a Double (1 watt value per second)
                    List<Double> values = Files.readAllLines(file.toPath())
                            .stream()
                            .map(String::trim)                // remove extra spaces
                            .filter(s -> !s.isEmpty())        // skip empty lines
                            .map(Double::parseDouble)         // convert to Double
                            .toList();

                    // Store 15-minute average blocks in this list
                    List<Map<String, Object>> intervals = new ArrayList<>();

                    // Go through the values in blocks of 900 (15 min = 900 seconds)
                    for (int i = 0; i < values.size(); i += 900) {
                        List<Double> chunk = values.subList(i, Math.min(i + 900, values.size()));

                        // Calculate the average of this chunk
                        double avg = chunk.stream().mapToDouble(d -> d).average().orElse(0.0);

                        // Determine the time label (e.g., 00:00, 00:15, etc.)
                        int mins = (i / 900) * 15;
                        LocalTime time = LocalTime.of(mins / 60, mins % 60);

                        // Add time + average value to the interval list
                        intervals.add(Map.of(
                            "time", time.toString().substring(0, 5), // format: "HH:mm"
                            "value", avg
                        ));
                    }

                    // Add the daily result to the final list
                    results.add(Map.of(
                        "device", deviceId,
                        "description", DEVICE_DESCRIPTIONS.getOrDefault(deviceId, "Unknown"),
                        "date", date,
                        "interval", "15min",
                        "data", intervals
                    ));
                }
            }

        } catch (Exception e) {
            e.printStackTrace(); // Log any file-reading or parsing errors
        }

        return results; // List of days with 15-min interval data
    }
}
