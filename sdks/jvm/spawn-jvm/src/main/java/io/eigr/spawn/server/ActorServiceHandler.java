package io.eigr.spawn.server;

import com.google.protobuf.Any;
import com.google.protobuf.InvalidProtocolBufferException;
import io.eigr.functions.protocol.Protocol;
import io.eigr.spawn.example.Example;
import lombok.extern.log4j.Log4j2;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@Log4j2
@RestController
@RequestMapping("/api/v1/actors")
public class ActorServiceHandler {

    @PostMapping(value = "/actions",
            consumes = {MediaType.APPLICATION_OCTET_STREAM_VALUE},
            produces = {MediaType.APPLICATION_OCTET_STREAM_VALUE}
    )
    public Mono<ResponseEntity<ByteArrayResource>> post(@RequestBody() byte[] data) throws InvalidProtocolBufferException {

        log.info("Received Actor action request: {}", data);
        Protocol.ActorInvocation actorInvocationRequest = Protocol.ActorInvocation.parseFrom(data);
        Protocol.Context context = actorInvocationRequest.getCurrentContext();

        String actor = actorInvocationRequest.getActorName();
        String system = actorInvocationRequest.getActorSystem();
        String commandName = actorInvocationRequest.getCommandName();

        Any value = actorInvocationRequest.getValue();
        Example.MyBusinessMessage myBusinessMessage = value.unpack(Example.MyBusinessMessage.class);

        log.info("Actor {} received Action invocation for command {}", actor, commandName);

        Any updatedState;
        int resultValue;

        resultValue = myBusinessMessage.getValue() + 1;

        Example.MyBusinessMessage valueMessage = Example.MyBusinessMessage.newBuilder()
                .setValue(resultValue)
                .build();

        updatedState = Any.pack(valueMessage);

        Protocol.Context updatedContext = Protocol.Context.newBuilder()
                .setState(updatedState)
                .build();

        Protocol.ActorInvocationResponse response = Protocol.ActorInvocationResponse.newBuilder()
                .setActorName(actor)
                .setActorSystem(system)
                .setUpdatedContext(updatedContext)
                .setValue(updatedState)
                .setValue(updatedState)
                .build();

        byte[] responseBytes = response.toByteArray();
        log.info("Response raw bytes: {}", responseBytes);
        ByteArrayResource resource = new ByteArrayResource(responseBytes);
        long length = resource.contentLength();
        log.info("Content length for ActorInvocationResponse: {}",length );

        return Mono.just(ResponseEntity
                .ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .contentLength(length)
                .body(resource));


    }

}
