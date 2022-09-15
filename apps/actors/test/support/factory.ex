defmodule Actors.FactoryTest do
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
    TimeoutStrategy,
    ActorSnapshotStrategy,
    ActorDeactivateStrategy,
    ActorState
  }

  alias Google.Protobuf.Any

  def encode_decode(record) do
    encoded = apply(record.__struct__, :encode, [record])

    apply(record.__struct__, :decode, [encoded])
  end

  def build_system(attrs \\ []) do
    ActorSystem.new(
      name: attrs[:name] || "test_system",
      registry: attrs[:registry] || nil
    )
  end

  def build_system_with_actors(attrs \\ []) do
    ActorSystem.new(
      name: attrs[:name] || "test_system",
      registry: attrs[:registry] || build_registry_with_actors()
    )
  end

  def build_registry_with_actors(attrs \\ []) do
    Registry.new(actors: attrs[:actors] || Enum.map(1..(attrs[:count] || 5), & build_actor_entry(name: "test_actor_#{&1}")))
  end

  def build_registration_request(attrs \\ []) do
    RegistrationRequest.new(
      service_info: attrs[:service_info] || build_service_info(),
      actor_system: attrs[:actor_system] || build_system()
    )
  end

  def build_invocation_request(attrs \\ []) do
    value = Any.new(
      type_url: get_type_url(Actors.Protos.ChangeNameTest),
      value: Actors.Protos.ChangeNameTest.new(new_name: "new_name") |> Actors.Protos.ChangeNameTest.encode()
    )

    InvocationRequest.new(
      system: attrs[:system] || build_system(),
      actor: attrs[:actor] || build_actor(),
      async: attrs[:async] || false,
      command_name: attrs[:command_name] || "ChangeNameTest",
      value: attrs[:value] || value
    )
  end

  def build_actor_entry(attrs \\ []) do
    default_name = Faker.Superhero.name()

    {attrs[:name] || default_name, attrs[:actor] || build_actor(name: attrs[:name] || default_name)}
  end

  def build_actor(attrs \\ []) do
    Actor.new(
      name: attrs[:name] || "#{Faker.Superhero.name()} #{Faker.StarWars.character()}",
      persistent: attrs[:persistent] || true,
      state: attrs[:state] || build_actor_state(),
      snapshot_strategy: attrs[:snapshot_strategy] || build_actor_snapshot_strategy(),
      deactivate_strategy: attrs[:deactivate_strategy] || build_actor_deactivate_strategy()
    )
  end

  def build_actor_state(attrs \\ []) do
    state = Any.new(
      type_url: get_type_url(Actors.Protos.StateTest),
      value: Actors.Protos.StateTest.new(name: "example_state_name_#{Faker.Superhero.name()}") |> Actors.Protos.StateTest.encode()
    )

    ActorState.new(
      state: Any.new(attrs[:state] || state)
    )
  end

  def build_actor_deactivate_strategy(attrs \\ []) do
    timeout = TimeoutStrategy.new(
      timeout: attrs[:timeout] || 60_000
    )

    ActorDeactivateStrategy.new(
      strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout}
    )
  end

  def build_actor_snapshot_strategy(attrs \\ []) do
    timeout = TimeoutStrategy.new(
      timeout: attrs[:timeout] || 60_000
    )

    ActorSnapshotStrategy.new(
      strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout}
    )
  end

  def build_service_info(attrs \\ []) do
    ServiceInfo.new(
      service_name: attrs[:service_name] || "test_service",
      service_version: attrs[:service_version] || "1.0.0",
      service_runtime: attrs[:service_runtime] || "test_runtime",
      support_library_name: attrs[:support_library_name] || "",
      support_library_version: attrs[:support_library_version] || "",
      protocol_major_version: attrs[:protocol_major_version] || 1,
      protocol_minor_version: attrs[:protocol_minor_version] || 1
    )
  end

  def build_host_invoke_response(attrs \\ []) do
    state = Any.new(
      type_url: get_type_url(Actors.Protos.ChangeNameTest),
      value: Actors.Protos.ChangeNameResponseTest.new(status: :OK, new_name: "new_name") |> Actors.Protos.ChangeNameTest.encode()
    )
    context = Eigr.Functions.Protocol.Context.new(state: attrs[:state] || state)
    ActorInvocationResponse.new(actor_name: attrs[:actor_name], system_name: attrs[:system_name], updated_context: attrs[:context] || context, value: attrs[:value] || state)
  end

  defp get_type_url(type) do
    parts =
      type
      |> to_string
      |> String.replace("Elixir.", "")
      |> String.split(".")

    package_name =
      with {_, list} <- parts |> List.pop_at(-1),
           do: list |> Enum.map(&String.downcase(&1)) |> Enum.join(".")

    type_name = parts |> List.last()

    "type.googleapis.com/#{package_name}.#{type_name}"
  end
end
