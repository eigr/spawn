package io.eigr.spawn;

import static org.junit.Assert.assertTrue;

import akka.NotUsed;
import akka.actor.typed.ActorSystem;
import akka.actor.typed.javadsl.Behaviors;
import akka.grpc.GrpcClientSettings;
import akka.stream.javadsl.AsPublisher;
import akka.stream.javadsl.Sink;
import akka.stream.javadsl.Source;
import com.google.protobuf.Any;
import com.google.protobuf.ByteString;
import io.eigr.functions.protocol.ActorServiceClient;
import io.eigr.functions.protocol.Protocol;
import io.eigr.functions.protocol.actors.ActorOuterClass;
import org.junit.Test;
import reactor.core.publisher.EmitterProcessor;
import scala.concurrent.duration.Duration;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;

/**
 * Unit test for simple App.
 */
public class AppTest {
    /**
     * Rigorous Test :-)
     */
    @Test
    public void shouldAnswerWithTrue() throws InterruptedException {
        final EmitterProcessor<Protocol.ActorSystemRequest> publisherStream = EmitterProcessor.create();
        final Source<Protocol.ActorSystemRequest, NotUsed> requestStream = Source.fromPublisher(publisherStream);

        final ActorSystem system = ActorSystem.create(Behaviors.empty(), "SpawnSystem");
        final GrpcClientSettings clientSettings = GrpcClientSettings.connectToServiceAt("localhost", 5001, system)
                .withConnectionAttempts(20)
                .withDeadline(Duration.Inf())
                .withTls(false);

        ActorServiceClient client = ActorServiceClient.create(clientSettings, system);

        System.out.println("Send spawn request...");
        final Source<Protocol.ActorSystemResponse, NotUsed> spawn  = client.spawn(requestStream);

        spawn.map(resp -> {
            System.out.println("Receive ActorSystemResponse message: " + resp);
            return resp;
                })
                .runWith(Sink.asPublisher(AsPublisher.WITH_FANOUT), system);



        HashMap<String, ActorOuterClass.Actor> actors = new HashMap<String, ActorOuterClass.Actor>();

        for (int i = 0; i < 1; i++) {
            String actorName = String.format("actor-test-0%s", i);
            actors.put(actorName, makeActor(actorName));
        }

        ActorOuterClass.Registry registry = ActorOuterClass.Registry.newBuilder()
                .putAllActors(actors)
                .build();

        ActorOuterClass.ActorSystem actorSystem = ActorOuterClass.ActorSystem.newBuilder()
                .setName("test-system")
                .setRegistry(registry)
                .build();

        Protocol.ServiceInfo si = Protocol.ServiceInfo.newBuilder()
                .setServiceName("jvm-sdk")
                .setServiceVersion("0.1.1")
                .setServiceRuntime(System.getProperty("java.version"))
                .setProtocolMajorVersion(1)
                .setProtocolMinorVersion(1)
                .build();

        Protocol.RegistrationRequest registration = Protocol.RegistrationRequest.newBuilder()
                .setServiceInfo(si)
                .setActorSystem(actorSystem)
                .build();

        Protocol.ActorSystemRequest registrationActorSystemMessage = Protocol.ActorSystemRequest.newBuilder()
                .setRegistrationRequest(registration)
                .build();

        System.out.println("Send registration request...");
        publisherStream.onNext(registrationActorSystemMessage);

        Thread.sleep(10000L);
        assertTrue(true);
    }

    private ActorOuterClass.Actor makeActor(String name) {
        Any stateValue = Any.newBuilder()
                .setTypeUrl("type.googleapis.com/string")
                .setValue(ByteString.copyFrom(String.format("test-%s", name).getBytes(StandardCharsets.UTF_8)))
                .build();

        ActorOuterClass.ActorState initialState = ActorOuterClass.ActorState.newBuilder()
                .setState(stateValue)
                .build();

        ActorOuterClass.ActorSnapshotStrategy snapshotStrategy = ActorOuterClass.ActorSnapshotStrategy.newBuilder()
                .setTimeout(ActorOuterClass.TimeoutStrategy.newBuilder().setTimeout(10000).build())
                .build();

        ActorOuterClass.ActorDeactivateStrategy deactivateStrategy = ActorOuterClass.ActorDeactivateStrategy.newBuilder()
                .setTimeout(ActorOuterClass.TimeoutStrategy.newBuilder().setTimeout(60000).build())
                .build();

        return ActorOuterClass.Actor.newBuilder()
                .setName(name)
                .setState(initialState)
                .setSnapshotStrategy(snapshotStrategy)
                .setDeactivateStrategy(deactivateStrategy)
                .build();
    }
}
