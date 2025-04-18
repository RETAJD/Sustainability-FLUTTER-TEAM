package com.example.demo.controller;

import com.example.demo.service.DataAggregatorService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api")
public class StatsController {

    private final DataAggregatorService service;

    public StatsController(DataAggregatorService service) {
        this.service = service;
    }

    @GetMapping("/averages")
    public Map<String, List<Map<String, Object>>> getAverages(@RequestParam String season) {
        return service.aggregateDataEvery15MinutesBySeason(season);
    }

}
