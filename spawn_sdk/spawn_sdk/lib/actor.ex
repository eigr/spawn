defmodule SpawnSdk.Actor do
  @moduledoc """
  Documentation for `Actor`.

  Actor look like this:

    defmodule MyActor do
      use SpawnSdk.Actor,
        name: "joe",
        persistent: false,
        state_type: Io.Eigr.Spawn.Example.MyState,
        deactivate_timeout: 5_000,
        snapshot_timeout: 2_000

      require Logger
      alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

      defact sum(%MyBusinessMessage{value: value} = data}, %Context{state: state} = ctx) do
        Logger.info("Received Request...")

        new_value = (state.value || 0) + value

        %Value{}
        |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
        |> Value.reply!()
      end
  """

  alias SpawnSdk.{
    ActorRef,
    ActorChannel,
    ActorGroupRef,
    Context,
    Value
  }

  @type system :: String.t()

  @type actor :: String.t()

  @type parent :: actor()

  @type group :: ActorGroup.t()

  @type opts :: [
          action: String.t() | atom() | nil,
          data: any() | nil,
          delay: integer() | nil,
          metadata: map() | nil,
          parent: ActorRef.t() | nil,
          pooled: boolean() | nil,
          scheduled_to: DateTime.t() | nil,
          spawn: boolean() | false
        ]

  @type action :: String.t()

  @type context :: Context.t()

  @type data :: module()

  @type error :: any()

  @type value :: Value.t()

  @callback handle_action({action(), data()}, context()) ::
              value() | {:reply, value()} | {:error, error()} | {:error, error(), value()}

  @spec channel(ActorChannel.t(), opts()) :: ActorChannel.t()
  def channel(channel, opts), do: %ActorChannel{channel: channel, opts: opts}

  @doc """
  Creates a reference to an actor so that it can be invoked.

  The first argument is ActorSystem name.
  The second argument is a Actor name.

  The third argument is a keyword list of options:

  * `spawn` - a boolean indicating whether the actor should be generated or not. Default is **false**.

  Example:

  ```
  iex(spawn_a@127.0.0.1)1> SpawnSdk.Actor.ref("spawn-system", "joe")
  %SpawnSdk.ActorRef{system: "spawn-system", name: "joe", opts: []}
  ```

  To invoke an actor using the obtained reference you could do:

  ```
  alias SpawnSdk.Actor

  my_data = %MyData{value: 1}

  Actor.ref("spawn-system", "joe")
  |> Actor.invoke(action: "sum", data: my_data)
  ```
  """
  @spec ref(system(), actor(), opts()) :: ActorRef.t()
  def ref(system, name, opts \\ []),
    do: %ActorRef{system: system, name: name, opts: opts}

  @spec group(list(ActorRef), opts()) :: ActorGroupRef.t()
  def group(actors, opts \\ []) when is_list(actors),
    do: %ActorGroupRef{actors: actors, opts: opts}

  @doc """
  Spawn an actor and return its reference.

  The first argument is ActorSystem name.
  The second argument is a Actor name.
  The third argument is a parent actor name.

  Example:

  ```
  iex(spawn_a@127.0.0.1)1> SpawnSdk.Actor.spawn("spawn-system", "joe", "unamed_actor")
  %SpawnSdk.ActorRef{system: "spawn-system", name: "joe", opts: []}
  ```

  To invoke an actor using the obtained reference you could do:

  ```
  alias SpawnSdk.Actor

  my_data = %MyData{value: 1}

  Actor.spawn("spawn-system", "joe", "unamed_actor")
  |> Actor.invoke(action: "sum", data: my_data)
  ```
  """
  @spec spawn(system(), actor(), parent(), opts()) :: ActorRef.t()
  def spawn(system, name, parent, opts \\ []) do
    :ok = SpawnSdk.spawn_actor(name, system: system, actor: parent)
    new_options = Keyword.merge(opts, parent: parent, already_spawned: true)
    %ActorRef{system: system, name: name, opts: new_options}
  end

  @doc """
  Creates a group of actor reference so that it can be invoked

  Example:

  ```
  alias SpawnSdk.Actor

  my_data = %MyData{value: 1}

  Actor.ref("erlang-system", "joe", action: :sum, data: my_data)
  |> Actor.to_group("erlang-system", "robert", action: :sum, data: my_data)
  |> Actor.multi()
  ```
  """
  @spec to_group(ActorRef.t(), opts()) :: ActorGroupRef.t()
  def to_group(%ActorRef{} = first, opts) do
    %ActorGroupRef{actors: [first], opts: opts}
  end

  @doc """
  Creates a group of actor reference so that it can be invoked

  Example:

  ```
  alias SpawnSdk.Actor

  my_data = %MyData{value: 1}

  Actor.ref("erlang-system", "joe")
  |> Actor.to_group("erlang-system", "robert")
  |> Actor.to_group("erlang-system", "mike")
  |> Actor.to_group("eigr-system", "adriano")
  |> Actor.to_group("eigr-system", "marcel")
  |> Actor.to_group("spawn-elixir-system", "elias")
  |> Actor.multi(action: :sum, data: my_data)
  ```
  """
  @spec to_group(ActorRef.t() | ActorGroupRef.t(), system(), actor(), opts()) :: ActorGroupRef.t()
  def to_group(ref, system, actor, opts \\ [])

  def to_group(%ActorRef{} = first, system, actor, opts) when is_nil(system) and is_nil(actor) do
    %ActorGroupRef{actors: [first], opts: opts}
  end

  def to_group(%ActorRef{} = first, system, actor, opts) do
    last = %ActorRef{system: system, name: actor, opts: opts}
    %ActorGroupRef{actors: [first] ++ last, opts: opts}
  end

  def to_group(%ActorGroupRef{actors: first} = ref, system, actor, opts) when is_list(first) do
    last = %ActorRef{system: system, name: actor, opts: opts}
    %ActorGroupRef{ref | actors: first ++ last}
  end

  @doc """
  Sends a assynchronous message to group of actors.

  Example:

  ```
  alias SpawnSdk.Actor

  Actor.ref("spawn-system", "joe")
  |> Actor.cast(action: "sum", data: %MyData{value: 1})
  ```
  """
  @spec cast(ActorRef.t(), opts()) :: {:ok, :async}
  def cast(%ActorRef{system: system, name: actor, opts: actor_opts} = _ref, opts) do
    spawn? = Keyword.get(actor_opts, :spawn, false) || Keyword.get(opts, :spawn, false)
    already_spawned? = Keyword.get(actor_opts, :already_spawned)
    new_opts = Keyword.merge(opts, system: system, async: true)

    case spawn? and not already_spawned? do
      true ->
        %ActorRef{system: _parent_system, name: parent_name} =
          _parent =
          Keyword.get(actor_opts, :parent) ||
            Keyword.get(opts, :parent)

        new_opts = Keyword.merge(new_opts, actor: parent_name)
        SpawnSdk.invoke(actor, new_opts)

      false ->
        SpawnSdk.invoke(actor, new_opts)
    end
  end

  @doc """
  Sends a message to the actor and returns the result.

  Example:

  ```
  alias SpawnSdk.Actor

  Actor.ref("spawn-system", "joe")
  |> Actor.invoke(action: "sum", data: %MyData{value: 1})
  ```
  """
  @spec invoke(ActorRef.t(), opts()) ::
          {:ok, any()} | {:error, any()}
  def invoke(%ActorRef{system: system, name: actor, opts: actor_opts} = _ref, opts) do
    spawn? = Keyword.get(actor_opts, :spawn, false) || Keyword.get(opts, :spawn, false)
    already_spawned? = Keyword.get(actor_opts, :already_spawned)
    new_opts = Keyword.merge(opts, system: system, async: false)

    case spawn? and not already_spawned? do
      true ->
        %ActorRef{system: _parent_system, name: parent_name} =
          _parent_name =
          Keyword.get(actor_opts, :parent) ||
            Keyword.get(opts, :parent)

        new_opts = Keyword.merge(new_opts, actor: parent_name)
        SpawnSdk.invoke(actor, new_opts)

      false ->
        SpawnSdk.invoke(actor, new_opts)
    end
  end

  @doc """
  Invokes a group of actors and returns all results.

  Example:

  ```
  alias SpawnSdk.Actor

  my_data = %MyData{value: 1}

  Actor.ref("erlang-system", "joe", action: :sum, data: my_data)
  |> Actor.to_group("erlang-system", "robert", action: :sum, data: my_data)
  |> Actor.to_group("erlang-system", "mike", action: :sum, data: my_data)
  |> Actor.to_group("eigr-system", "adriano", action: :sum, data: my_data)
  |> Actor.to_group("eigr-system", "marcel", action: :sum, data: my_data)
  |> Actor.to_group("spawn-elixir-system", "elias"", action: "calc", data: my_data)
  |> Actor.multi()
  ```
  """
  @spec multi(ActorGroupRef.t()) :: list(any()) | {:error, any()}
  def multi(%ActorGroupRef{actors: actors} = _ref) do
    tasks =
      Enum.map(actors, fn %ActorRef{opts: actor_opts} = actor ->
        Task.async(fn -> invoke(actor, actor_opts) end)
      end)

    Task.await_many(tasks)
  end

  @spec pub(ActorChannel.t(), opts()) :: :ok
  def pub(%ActorChannel{} = _channel, _opts) do
    # TODO: implement this in Proxy too?
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias SpawnSdk.{
        Context,
        Flow.Broadcast,
        Flow.Pipe,
        Flow.Forward,
        Flow.SideEffect,
        Value
      }

      import SpawnSdk.Actor
      use SpawnSdk.Defact

      import SpawnSdk.System.SpawnSystem,
        only: [
          invoke: 2,
          register: 2,
          spawn_actor: 2
        ]

      Module.register_attribute(__MODULE__, :actor_opts, persist: true)
      Module.put_attribute(__MODULE__, :actor_opts, opts)

      @behaviour SpawnSdk.Actor
      @before_compile SpawnSdk.Actor
    end
  end

  defmacro __before_compile__(_a) do
    opts = Module.get_attribute(__CALLER__.module, :actor_opts)
    actions = Module.get_attribute(__CALLER__.module, :defact_exports)

    actor_name = Keyword.get(opts, :name, Atom.to_string(__CALLER__.module))
    actor_kind = Keyword.get(opts, :kind, :SINGLETON)
    caller_module = __CALLER__.module
    channel_group = Keyword.get(opts, :channel, nil)

    min_pool_size = Keyword.get(opts, :min_pool_size, 1)
    max_pool_size = Keyword.get(opts, :max_pool_size, 0)

    state_type = Keyword.get(opts, :state_type, :json)
    stateful = Keyword.get(opts, :stateful, true)

    tags = Keyword.get(opts, :tags, nil)

    if stateful and !Code.ensure_loaded?(Statestores.Supervisor) do
      raise """
      ArgumentError. You need to add :spawn_statestores to your dependency if you are going to use persistent actors.
      Otherwise, set `stateful: false` in your Actor attributes
      """
    end

    if state_type == nil and stateful do
      raise "ArgumentError. State type is mandatory if stateful is true"
    end

    if stateful and actor_kind == :POOLED do
      raise ArgumentError, """
      Pooled Actors cannot be stateful.
      Please set stateful attribute to false to be able to register Actor #{actor_name}
      """
    end

    deactivate_timeout = Keyword.get(opts, :deactivate_timeout, 10_000)
    snapshot_timeout = Keyword.get(opts, :snapshot_timeout, 2_000)

    quote do
      def __meta__(:actions) do
        unquote(actions)
        |> Enum.filter(fn {_action, %{timer: timer}} -> is_nil(timer) end)
        |> Enum.map(fn {action, %{timer: timer}} -> action end)
      end

      def __meta__(:timers) do
        unquote(actions)
        |> Enum.reject(fn {_action, %{timer: timer}} -> is_nil(timer) end)
        |> Enum.map(fn {action, %{timer: timer}} -> {action, timer} end)
      end

      def __meta__(:channel), do: unquote(channel_group)

      def __meta__(:name) do
        actor_name = unquote(actor_name)
        kind = unquote(actor_kind)

        if kind == :ABSTRACT do
          unless :persistent_term.get("actor:#{actor_name}", false) do
            :persistent_term.put("actor:#{actor_name}", unquote(caller_module))
          end

          actor_name
        else
          actor_name
        end
      end

      def __meta__(:kind), do: unquote(actor_kind)
      def __meta__(:stateful), do: unquote(stateful)
      def __meta__(:state_type), do: unquote(state_type)
      def __meta__(:min_pool_size), do: unquote(min_pool_size)
      def __meta__(:max_pool_size), do: unquote(max_pool_size)
      def __meta__(:snapshot_timeout), do: unquote(snapshot_timeout)
      def __meta__(:deactivate_timeout), do: unquote(deactivate_timeout)
      def __meta__(:tags), do: Map.new(unquote(tags) || %{})
    end
  end
end
