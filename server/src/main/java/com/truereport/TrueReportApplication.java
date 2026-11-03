package com.truereport;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class TrueReportApplication {
    public static void main(String[] args) {
        SpringApplication.run(TrueReportApplication.class, args);
    }
}
