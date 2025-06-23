package com.example.demo.service;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PlugDataService {
// changed base path
    private static final String BASE_FOLDER = "classpath:/01_plugs_csv/";

    private static final Map<String, String> DEVICE_DESCRIPTIONS = Map.of(
        "01", "Fridge",
        "02", "Dryer",
        "03", "Coffee machine",
        "04", "Kettle",
        "05", "Washing machine",
        "06", "PC",
        "07", "Freezer"
    );

    @Cacheable(value = "plugDeviceCache", key = "#deviceId + '-' + #interval")
    public List<Map<String, Object>> getAggregatedDataForDevice(String deviceId, int interval) {
        // String folderPath = BASE_FOLDER + deviceId;
        // File[] files;
        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        List<Map<String, Object>> results = new ArrayList<>();
        try {
            // Automatically load all .csv files in the classpath folder
            Resource[] resources = resolver.getResources(BASE_FOLDER + deviceId + "/*.csv");

            Arrays.sort(resources, Comparator.comparing(Resource::getFilename));

            for (Resource resource : resources) {
                results.add(processDeviceFile(resource, deviceId, interval));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return results.stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }
    //     try {
    //         File folder = new File(getClass().getResource(folderPath).toURI());
    //         files = folder.listFiles((dir, name) -> name.endsWith(".csv"));
    //         if (files == null) return Collections.emptyList();
    //         System.out.println(folder);
    //         Arrays.sort(files); // sort files by date name

    //         return Arrays.stream(files)
    //                 .parallel()
    //                 .map(file -> processDeviceFile(file, deviceId, interval))
    //                 .filter(Objects::nonNull)
    //                 .collect(Collectors.toList());

    //     } catch (Exception e) {
    //         e.printStackTrace();
    //         return Collections.emptyList();
    //     }
    // }

    // private Map<String, Object> processDeviceFile(File file, String deviceId, int interval) {
    private Map<String, Object> processDeviceFile(Resource resource, String deviceId, int interval) {
        try {
            // String date = file.getName().replace(".csv", "");
            String date = Objects.requireNonNull(resource.getFilename()).replace(".csv", "");
            List<Double> values = new ArrayList<>();
            // try (BufferedReader reader = Files.newBufferedReader(file.toPath())) {
            // try (InputStream stream = PlugDataService.class.getClassLoader().getResourceAsStream("/01_plugs_csv/" + deviceId + "/" + file.getName()))
            // {   
                // BufferedReader reader = new BufferedReader(new InputStreamReader(stream));
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    line = line.trim();
                    if (!line.isEmpty()) {
                        values.add(Double.parseDouble(line));
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
                intervals.add(Map.of(
                    "time", time.toString().substring(0, 5),
                    "value", avg
                ));
            }

            return Map.of(
                "device", deviceId,
                "description", DEVICE_DESCRIPTIONS.getOrDefault(deviceId, "Unknown"),
                "date", date,
                "interval", interval + "min",
                "data", intervals
            );

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
