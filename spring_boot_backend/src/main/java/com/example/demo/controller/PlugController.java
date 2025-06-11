package com.example.demo.controller;

import com.example.demo.service.PlugDataService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
@CrossOrigin(origins = "*") 
@RestController
@RequestMapping("plugs/01")
public class PlugController {

    private final PlugDataService plugDataService;

    public PlugController(PlugDataService plugDataService) {
        this.plugDataService = plugDataService;
    }

    @GetMapping("/{deviceId}")
    public List<Map<String, Object>> getPlugData(@PathVariable String deviceId, @RequestParam int interval) {
        return plugDataService.getAggregatedDataForDevice(deviceId, interval);
    }
}
