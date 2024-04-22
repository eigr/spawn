defmodule Actors.FactoryTest do
  @moduledoc false

  alias Eigr.Functions.Protocol.{
    RegistrationRequest,
    InvocationRequest,
    ActorInvocationResponse,
    ServiceInfo
  }

  alias Eigr.Functions.Protocol.Actors.{
    Registry,
    ActorSystem,
    Actor,
    ActorId,
    ActorSettings,
    TimeoutStrategy,
    ActorSnapshotStrategy,
    ActorDeactivationStrategy,
    ActorState,
    Action,
    Metadata
  }

  alias Google.Protobuf.Any

  def encode_decode(record) do
    encoded = apply(record.__struct__, :encode, [record])

    apply(record.__struct__, :decode, [encoded])
  end

  def build_system(attrs \\ []) do
    %ActorSystem{
      name: attrs[:name] || "spawn-system",
      registry: attrs[:registry] || nil
    }
  end

  def build_system_with_actors(attrs \\ []) do
    %ActorSystem{
      name: attrs[:name] || "test_system",
      registry: attrs[:registry] || build_registry_with_actors()
    }
  end

  def build_registry_with_actors(attrs \\ []) do
    %Registry{
      actors:
        attrs[:actors] ||
          Enum.reduce(
            1..(attrs[:count] || 5),
            %{},
            &Map.merge(build_actor_entry(name: "test_actor_#{&1}"), &2)
          )
    }
  end

  def build_registration_request(attrs \\ []) do
    %RegistrationRequest{
      service_info: attrs[:service_info] || build_service_info(),
      actor_system: attrs[:actor_system] || build_system()
    }
  end

  def build_invocation_request(attrs \\ []) do
    value = %Any{
      type_url: get_type_url(Actors.Protos.ChangeNameTest),
      value:
        %Actors.Protos.ChangeNameTest{new_name: "new_name"}
        |> Actors.Protos.ChangeNameTest.encode()
    }

    %InvocationRequest{
      system: attrs[:system] || build_system(),
      actor: attrs[:actor] || build_actor(),
      async: attrs[:async] || false,
      action_name: attrs[:action_name] || "ChangeNameTest",
      payload: {:value, attrs[:value] || value},
      caller: attrs[:caller] || nil,
      metadata: attrs[:metadata] || %{},
      scheduled_to: attrs[:scheduled_to] || nil
    }
  end

  def build_actor_entry(attrs \\ []) do
    default_name = "#{inspect(make_ref())}"

    %{
      (attrs[:name] || default_name) =>
        attrs[:actor] || build_actor(name: attrs[:name] || default_name)
    }
  end

  def build_actor(attrs \\ []) do
    actor_name = attrs[:name] || "#{inspect(make_ref())}"

    %Actor{
      id: %ActorId{name: actor_name, system: attrs[:system]},
      actions: attrs[:actions] || [build_actor_action()],
      settings: %ActorSettings{
        stateful: Keyword.get(attrs, :stateful, true),
        snapshot_strategy: attrs[:snapshot_strategy] || build_actor_snapshot_strategy(),
        deactivation_strategy:
          attrs[:deactivation_strategy] || build_actor_deactivation_strategy()
      },
      metadata: attrs[:metadata] || %Metadata{},
      state: attrs[:state] || build_actor_state()
    }
  end

  def build_actor_action(attrs \\ []) do
    %Action{name: attrs[:name] || "ChangeNameTest"}
  end

  def build_actor_state(attrs \\ []) do
    state =
      any_pack!(%Actors.Protos.StateTest{name: "example_state_name_#{inspect(make_ref())}"})

    %ActorState{state: Any.new(attrs[:state] || state)}
  end

  def build_actor_deactivation_strategy(attrs \\ []) do
    timeout = %TimeoutStrategy{timeout: attrs[:timeout] || 60_000}

    %ActorDeactivationStrategy{
      strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout}
    }
  end

  def build_actor_snapshot_strategy(attrs \\ []) do
    timeout = %TimeoutStrategy{timeout: attrs[:timeout] || 60_000}

    %ActorSnapshotStrategy{strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout}}
  end

  def build_service_info(attrs \\ []) do
    %ServiceInfo{
      service_name: attrs[:service_name] || "test_service",
      service_version: attrs[:service_version] || "1.3.1",
      service_runtime: attrs[:service_runtime] || "test_runtime",
      support_library_name: attrs[:support_library_name] || "",
      support_library_version: attrs[:support_library_version] || "",
      protocol_major_version: attrs[:protocol_major_version] || 1,
      protocol_minor_version: attrs[:protocol_minor_version] || 1
    }
  end

  def build_host_invoke_response(attrs \\ []) do
    state = %Actors.Protos.ChangeNameResponseTest{status: :OK, new_name: "new_name"} |> any_pack!

    context = %Eigr.Functions.Protocol.Context{
      self: %ActorId{name: attrs[:actor_name], system: attrs[:system_name]},
      caller: attrs[:state] || nil,
      state: attrs[:state] || state,
      tags: attrs[:tags] || %{}
    }

    %ActorInvocationResponse{
      actor_name: attrs[:actor_name],
      actor_system: attrs[:system_name],
      updated_context: attrs[:context] || context,
      payload: {:value, attrs[:value] || state}
    }
  end

  def any_pack!(record) do
    %Any{
      type_url: get_type_url(record.__struct__),
      value: apply(record.__struct__, :encode, [record])
    }
  end

  def any_unpack!(any_record, builder) do
    builder.decode(any_record.value)
  end

  defp get_type_url(type) do
    parts =
      type
      |> to_string
      |> String.replace("Elixir.", "")
      |> String.split(".")

    package_name =
      with {_, list} <- parts |> List.pop_at(-1),
           do: Enum.map_join(list, ",", &String.downcase/1)

    type_name = parts |> List.last()

    "type.googleapis.com/#{package_name}.#{type_name}"
  end
end
