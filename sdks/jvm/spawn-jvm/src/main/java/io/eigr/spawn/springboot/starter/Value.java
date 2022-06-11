package io.eigr.spawn.springboot.starter;

public final class Value<S, V> {

    enum ResponseType {
        REPLY, NO_REPLY
    }

    private final S state;

    private final V value;

    private final ResponseType type;

    public Value(V value, S state, ResponseType type) {
        this.value = value;
        this.state = state;
        this.type = type;
    }

    public V getValue() {
        return value;
    }

    public S getState() {
        return state;
    }

    public ResponseType getType() {
        return type;
    }

    public static final class ActorValue {
        private Object state;
        private Object value;

        public ActorValue(){}

        public static ActorValue at() {
            return new ActorValue();
        }

        public ActorValue value(Object value) {
            this.value = value;
            return this;
        }

        public ActorValue state(Object state){
            this.state = state;
            return this;
        }

        public Value reply() {
            return new Value(this.value, this.state, ResponseType.REPLY);
        }

        public Value noReply() {
            return new Value(this.value, this.state, ResponseType.NO_REPLY);
        }
    }
}
