package io.eigr.spawn.springboot.starter;

public final class ActorContext<S extends Object> {

    private final S state;

    public ActorContext(S state) {
        this.state = state;
    }

    public S getState()  {
        return state;
    }

}
