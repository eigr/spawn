package io.eigr.spawn.springboot.starter;

import io.eigr.spawn.example.Example;
import io.eigr.spawn.springboot.starter.annotations.ActorEntity;
import io.eigr.spawn.springboot.starter.annotations.Command;

@ActorEntity(name = "springboot-test-actor")
public class TestActor {

    @Command(name = "sum", inputType = Example.MyBusinessMessage.class)
    public Value<Example.MyBusinessMessage, Example.MyBusinessMessage> sum(Example.MyBusinessMessage msg) {
        int value = msg.getValue() + 1;

        Example.MyBusinessMessage resultValue = Example.MyBusinessMessage.newBuilder()
                .setValue(value)
                .build();

        return Value.ActorValue.at()
                .value(resultValue)
                .state(resultValue)
                .send();
    }

}
