package com.example.demo.controller;

import com.example.demo.service.PlugDataService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/plugs")
public class PlugController {

    private final PlugDataService plugDataService;

    public PlugController(PlugDataService plugDataService) {
        this.plugDataService = plugDataService;
    }

    @GetMapping("/{deviceId}")
    public List<Map<String, Object>> getPlugData(@PathVariable String deviceId) {
        return plugDataService.getAggregatedDataForDevice(deviceId);
    }
}
