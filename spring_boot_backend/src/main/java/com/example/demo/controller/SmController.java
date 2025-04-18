package com.example.demo.controller;

import com.example.demo.service.SmDataService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
@RestController
@RequestMapping("/api/sm")
public class SmController {

    private final SmDataService smDataService;

    public SmController(SmDataService smDataService) {
        this.smDataService = smDataService;
    }

    @GetMapping
    public List<Map<String, Object>> getData() {
        return smDataService.getAggregatedDataForSm();
    }
}
