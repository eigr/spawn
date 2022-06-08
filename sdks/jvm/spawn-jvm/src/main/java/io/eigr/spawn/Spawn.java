package io.eigr.spawn;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication
@EnableAutoConfiguration
@EntityScan("io.eigr.spawn")
public class Spawn {
    public static void main(String[] args) {
        SpringApplication.run(Spawn.class, args);
    }
}
