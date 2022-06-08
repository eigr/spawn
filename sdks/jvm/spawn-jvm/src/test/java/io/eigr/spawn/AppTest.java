package io.eigr.spawn;

import com.google.protobuf.Any;
import com.google.protobuf.ByteString;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import io.eigr.functions.protocol.Protocol;
import io.eigr.functions.protocol.actors.ActorOuterClass;
import io.eigr.spawn.example.Example;
import okhttp3.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigInteger;
import java.util.HashMap;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertTrue;

@SpringBootTest
@RunWith(SpringJUnit4ClassRunner.class)
public class AppTest {

    private final OkHttpClient client = new OkHttpClient();

    /**
     * Rigorous Test :-)
     */
    @Test
    public void shouldAnswerWithTrue() throws IOException, InterruptedException {

        HashMap<String, ActorOuterClass.Actor> actors = new HashMap<>();
        for (int i = 0; i < 2; i++) {
            String actorName = String.format("actor-test-0%s", i);
            actors.put(actorName, makeActor(actorName, i));
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

        RequestBody body = RequestBody.create(
                registration.toByteArray(), MediaType.parse("application/octet-stream"));

        Request request = new Request.Builder()
                .url("http://localhost:9001/api/v1/system")
                .post(body)
                .build();

        System.out.println("Send registration request...");

        Call call = client.newCall(request);
        Response invocationResponse;
        try (Response response = call.execute()) {

            assertThat(response.code(), equalTo(200));
            assert response.body() != null;
            Protocol.RegistrationResponse registrationResponse = Protocol.RegistrationResponse.parseFrom(response.body().bytes());
            System.out.println("Registration response: " + registrationResponse);

            // Send Invocation to Actor
            Example.MyBussinessMessage valueMessage = Example.MyBussinessMessage.newBuilder()
                    .setValue(10)
                    .build();

            Any stateValue = Any.pack(valueMessage);

            Protocol.InvocationRequest invocationRequest = Protocol.InvocationRequest.newBuilder()
                    .setAsync(false)
                    .setSystem(actorSystem)
                    .setActor(makeActor("actor-test-01", 1))
                    .setCommandName("someFunction")
                    .setValue(stateValue)
                    .build();

            RequestBody invocationBody = RequestBody.create(
                    invocationRequest.toByteArray(), MediaType.parse("application/octet-stream"));

            Request httpInvocationRequest = new Request.Builder()
                    .url("http://localhost:9001/api/v1/system/test-system/actors/actor-test-01/invoke")
                    .post(invocationBody)
                    .build();

            Thread.sleep(10000);

            System.out.println("Send Invocation request...");
            Call invocationCall = client.newCall(httpInvocationRequest);
            invocationResponse = invocationCall.execute();
            System.out.println("Invocation response: " + invocationResponse);
            assertThat(response.code(), equalTo(200));
        }

        Thread.sleep(10000);

        assertTrue(true);
    }

    private ActorOuterClass.Actor makeActor(String name, Integer state) {

        Example.MyBussinessMessage valueMessage = Example.MyBussinessMessage.newBuilder()
                .setValue(state)
                .build();

        Any stateValue = Any.pack(valueMessage);

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

    private static class SpawnUserFunctionHttpHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange httpExchange) throws IOException {
            System.out.printf("HTTP Exchange -> %s\n", httpExchange);
            InputStream requestStream = httpExchange.getRequestBody();
            System.out.println(requestStream);
            byte[] actorInvocationArray = new byte[requestStream.available()];
            requestStream.read(actorInvocationArray);

            Protocol.ActorInvocation actorInvocationRequest = Protocol.ActorInvocation.parseFrom(actorInvocationArray);
            System.out.println("Received ActorInvocation: " + actorInvocationRequest);
            handleResponse(httpExchange, actorInvocationRequest);
        }

        private void handleResponse(HttpExchange httpExchange, Protocol.ActorInvocation actorInvocationRequest) throws IOException {
            OutputStream outputStream = httpExchange.getResponseBody();

            ActorOuterClass.Actor actor = actorInvocationRequest.getInvocationRequest().getActor();
            ActorOuterClass.ActorSystem system = actorInvocationRequest.getInvocationRequest().getSystem();
            String commandName = actorInvocationRequest.getInvocationRequest().getCommandName();
            Any value = actorInvocationRequest.getInvocationRequest().getValue();
            String typeUrl = value.getTypeUrl();
            ByteString reqValue = value.getValue();

            System.out.printf("Actor %s received Action invocation for command %s%n", actor.getName(), commandName);

            Any updatedState = null;
            long resultValue;

            if (typeUrl.equalsIgnoreCase("type.googleapis.com/integer")) {
                long r = Long.parseLong(reqValue.toString());
                resultValue = r + 1L;

                byte[] byteState = BigInteger.valueOf(resultValue).toByteArray();

                updatedState = Any.newBuilder()
                        .setTypeUrl("type.googleapis.com/integer")
                        .setValue(ByteString.copyFrom(byteState))
                        .build();

            } else if (typeUrl.equalsIgnoreCase("type.googleapis.com/string")) {
                updatedState = Any.newBuilder()
                        .setTypeUrl("type.googleapis.com/integer")
                        .setValue(ByteString.copyFrom(reqValue.toByteArray()))
                        .build();
            }

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

            httpExchange.sendResponseHeaders(200, responseBytes.length);

            outputStream.write(responseBytes);
            outputStream.flush();
            outputStream.close();
        }

    }
}
