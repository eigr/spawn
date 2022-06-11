package io.eigr.spawn.springboot.starter.autoconfigure;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(SpawnProperties.class)
@ComponentScan(basePackages = "io.eigr.spawn.springboot.starter")
public class SpawnAutoConfiguration {
}
