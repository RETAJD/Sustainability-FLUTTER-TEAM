package com.example.demo.controller;

import com.example.demo.service.SmDataService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
@CrossOrigin(origins = "*") 
@RestController
@RequestMapping("/smartmeter")
public class SmController {

    private final SmDataService smDataService;

    public SmController(SmDataService smDataService) {
        this.smDataService = smDataService;
    }

    @GetMapping("/{column}")
    public List<Map<String, Object>> getData(@PathVariable String column, @RequestParam int interval) {
        return smDataService.getAggregatedDataForSm(column, interval);
    }
}
