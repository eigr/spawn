package io.eigr.spawn.server;

import com.google.protobuf.Any;
import com.google.protobuf.InvalidProtocolBufferException;
import io.eigr.functions.protocol.Protocol;
import io.eigr.functions.protocol.actors.ActorOuterClass;
import io.eigr.spawn.example.Example;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

@Log4j2
@RestController
@RequestMapping("/api/v1/actors")
public class ActorServiceHandler {

    @PostMapping(value = "/actions",
            consumes = {MediaType.APPLICATION_OCTET_STREAM_VALUE},
            produces = {MediaType.APPLICATION_OCTET_STREAM_VALUE}
    )
    public Mono<ServerResponse> post(@RequestBody() byte[] data) throws InvalidProtocolBufferException {
        log.info("Received Actor action request: {}", data);
        Protocol.ActorInvocation actorInvocationRequest = Protocol.ActorInvocation.parseFrom(data);
        ActorOuterClass.Actor actor = actorInvocationRequest.getInvocationRequest().getActor();
        ActorOuterClass.ActorSystem system = actorInvocationRequest.getInvocationRequest().getSystem();
        String commandName = actorInvocationRequest.getInvocationRequest().getCommandName();
        Any value = actorInvocationRequest.getInvocationRequest().getValue();
        Example.MyBussinessMessage myBussinessMessage = value.unpack(Example.MyBussinessMessage.class);

        log.info("Actor {} received Action invocation for command {}", actor.getName(), commandName);

        Any updatedState;
        int resultValue;

        resultValue = myBussinessMessage.getValue() + 1;

        Example.MyBussinessMessage valueMessage = Example.MyBussinessMessage.newBuilder()
                .setValue(resultValue)
                .build();

        updatedState = Any.pack(valueMessage);

        Protocol.ActorInvocationResponse response = Protocol.ActorInvocationResponse.newBuilder()
                .setUpdatedState(updatedState)
                .setInvocationResponse(
                        Protocol.InvocationResponse.newBuilder()
                                .setActor(actor)
                                .setSystem(system)
                                .setStatus(
                                        Protocol.RequestStatus.newBuilder()
                                                .setStatus(Protocol.Status.OK)
                                                .build())
                                .build())
                .getDefaultInstanceForType();

        byte[] responseBytes = response.toByteArray();
        return ServerResponse
                .ok()
                //.header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_OCTET_STREAM_VALUE)
                .bodyValue(responseBytes);
    }

}
