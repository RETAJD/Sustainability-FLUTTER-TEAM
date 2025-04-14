package com.example.demo.controller;

import com.example.demo.service.DataAggregatorService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class StatsController {

    private final DataAggregatorService service;

    public StatsController(DataAggregatorService service) {
        this.service = service;
    }

    @GetMapping("/weekly-averages")
    public Map<String, Double> getAverages() {
        return service.getWeeklyAverages();
    }
}
