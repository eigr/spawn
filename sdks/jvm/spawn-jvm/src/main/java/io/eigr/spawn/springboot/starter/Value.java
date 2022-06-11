package io.eigr.spawn.springboot.starter;

import com.google.protobuf.GeneratedMessageV3;

import java.util.Objects;

public final class Value<S extends GeneratedMessageV3, V extends GeneratedMessageV3> {

    private S state;

    private V value;

    public Value(V value) {
        this.value = value;
    }

    public Value(V value, S state) {
        this.value = value;
        this.state = state;
    }

    public static final class ActorValue<S extends GeneratedMessageV3, V extends GeneratedMessageV3> {
        private S state;
        private V value;

        public ActorValue(){}

        public static ActorValue at() {
            return new ActorValue();
        }

        public ActorValue value(V value) {
            this.value = value;
            return this;
        }

        public ActorValue state(S state){
            this.state = state;
            return this;
        }

        public Value send() {
            if (Objects.isNull(this.state)) {
                return new Value(this.value);
            }

            return new Value(this.value, this.state);
        }
    }
}
