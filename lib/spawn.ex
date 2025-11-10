defmodule Spawn do
  @moduledoc """
  Spawn provides an actor-based runtime for building durable, stateful systems.
  It enables you to implement business logic as actors that maintain persistent
  state across failures, scale horizontally, and communicate through modern
  protocols such as gRPC and HTTP.

  Actors are defined once using Protobuf service definitions. Spawn then
  automatically exposes them over gRPC and supports JSON transcoding for HTTP
  clients without requiring additional code changes.

  ## Main features:

    * 
    * 
    * 
    * 

    
  ## Installation:

     def deps do
        [
          {:spawn_sdk, "~> 2.0.0-RC9"},
          # You can uncomment one of those dependencies if you are going to use Persistent Actors
          # {:spawn_statestores_mariadb, "~> 2.0.0-RC9"},
          # {:spawn_statestores_postgres, "~> 2.0.0-RC9"}
        ]
      end

  ## Code generation

  After creating an Elixir application project, create the protobuf files for your business domain.
  It is common practice to do this under the **priv/** folder. Let's demonstrate an example:

  ```protobuf
  syntax = "proto3";

  package io.eigr.spawn.example;

  message MyState {
  int32 value = 1;
  }

  message MyBusinessMessage {
  int32 value = 1;
  }
  ```

  It is important to try to separate the type of message that must be stored as the actors' state from the type of messages
  that will be exchanged between their actors' operations calls. In other words, the Actor's internal state is also represented
  as a protobuf type, and it is a good practice to separate these types of messages from the others in its business domain.

  In the above case `MyState` is the type protobuf that represents the state of the Actor that we will create later
  while `MyBusiness` is the type of message that we will send and receive from this Actor.

  Now that we have defined our input and output types as Protobuf types we will need to compile these files to generate their respective Elixir modules. An example of how to do this can be found [here](https://github.com/eigr/spawn/blob/main/spawn_sdk/spawn_sdk_example/compile-example-pb.sh)

  You need to have installed the elixir plugin for protoc. More information on how to obtain and install the necessary tools can be found here [here](https://github.com/elixir-protobuf/protobuf#usage)

  Now that the protobuf types have been created we can proceed with the code.

  ## Basic Example

     defmodule SpawnSdkExample.Actors.MyActor do
       use SpawnSdk.Actor,
         name: "jose", # Default is Full Qualified Module name a.k.a __MODULE__
         kind: :named, # Default is already :named. Valid are :named | :unnamed
         stateful: true, # Default is already true
         state_type: Io.Eigr.Spawn.Example.MyState, # or :json if you don't care about protobuf types

      require Logger

      alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

      # The callback could also be referenced to an existing function:
      # action "SomeAction", &some_defp_handler/0
      # action "SomeAction", &SomeModule.handler/1
      # action "SomeAction", &SomeModule.handler/2

      init fn %Context{state: state} = ctx ->
        Logger.info("[joe] Received activation request")

        Value.of()
        |> Value.state(state)
      end

      action "Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
        Logger.info("Received Request. Doing something...")

        new_value = if is_nil(state), do: value, else: (state.value || 0) + value

        Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
      end
    end


  """
  @version GRPC.Mixfile.project()[:version]

  @doc """
  Returns version of this project.
  """
  def version, do: @version
end
