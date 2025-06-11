package com.example.demo.controller;

import com.example.demo.service.DataAggregatorService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.List;
@CrossOrigin(origins = "*") 
@RestController
@RequestMapping("/occupancy/01")
public class StatsController {

    private final DataAggregatorService service;

    public StatsController(DataAggregatorService service) {
        this.service = service;
    }

    @GetMapping("/{season}")
    public List<Map<String, Object>> getAverages(@PathVariable String season, @RequestParam int interval) {
        return service.aggregateDataEvery15MinutesBySeason(season, interval);
    }

}
