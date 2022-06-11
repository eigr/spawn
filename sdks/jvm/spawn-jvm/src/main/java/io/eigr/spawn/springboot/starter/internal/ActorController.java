package io.eigr.spawn.springboot.starter.internal;

import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

@Component
public final class ActorController {

    private final ApplicationContext applicationContext;

    public ActorController(ApplicationContext applicationContext){
        this.applicationContext = applicationContext;
    }
}
