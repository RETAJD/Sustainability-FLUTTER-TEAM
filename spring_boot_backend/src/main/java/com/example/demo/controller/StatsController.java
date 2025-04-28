package com.example.demo.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.service.DataAggregatorService;

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
