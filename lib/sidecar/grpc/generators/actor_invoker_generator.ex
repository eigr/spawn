defmodule Sidecar.GRPC.Generators.ActorInvoker do
  @moduledoc """
  Module for generating an actor invoker helper.
  """
  @behaviour ProtobufGenerate.Plugin

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    <%= if @render do %>
    defmodule <%= @module %> do
      @moduledoc "This module provides helper functions for invoking the methods on the <%= @service_name %> actor."

      @doc \"\"\"
      Invokes the get_state implicit action for this actor.

      ## Examples
      ```elixir
      iex> <%= @module %>.get_state()
      {:ok, actor_state}
      ```
      \"\"\"
      def get_state do
        %SpawnSdk.ActorRef{system: "<%= @actor_system %>", name: "<%= @actor_name %>"}
        |> get_state()
      end

      @doc \"\"\"
      Invokes the get_state implicit action.

      ## Parameters
      - `ref` - The actor ref to send the action to.

      ## Examples
      ```elixir
      iex> <%= @module %>.get_state(SpawnSdk.Actor.ref("<%= @actor_system %>", "actor_id_01"))
      {:ok, actor_state}
      ```
      \"\"\"
      def get_state(%SpawnSdk.ActorRef{} = ref) do
        opts = [
          system: ref.system || "<%= @actor_system %>",
          action: "get_state",
          async: false
        ]

        actor_to_invoke = ref.name || "<%= @actor_name %>"

        opts = if actor_to_invoke == "<%= @actor_name %>" do
          opts
        else
          Keyword.put(opts, :ref, "<%= @actor_name %>")
        end

        SpawnSdk.invoke(actor_to_invoke, opts)
      end

      <%= for {method_name, input, output, _options} <- @methods do %>
        def <%= Macro.underscore(method_name) %>() do
          %SpawnSdk.ActorRef{system: "<%= @actor_system %>", name: "<%= @actor_name %>"}
          |> <%= Macro.underscore(method_name) %>(%<%= input %>{}, []) 
        end

        def <%= Macro.underscore(method_name) %>(%<%= input %>{} = payload) do
          %SpawnSdk.ActorRef{system: "<%= @actor_system %>", name: "<%= @actor_name %>"}
          |> <%= Macro.underscore(method_name) %>(payload, []) 
        end

        def <%= Macro.underscore(method_name) %>(%<%= input %>{} = payload, opts) when is_list(opts) do
          %SpawnSdk.ActorRef{system: "<%= @actor_system %>", name: "<%= @actor_name %>"}
          |> <%= Macro.underscore(method_name) %>(payload, opts) 
        end

        def <%= Macro.underscore(method_name) %>(%SpawnSdk.ActorRef{} = ref, %<%= input %>{} = payload) do
          ref
          |> <%= Macro.underscore(method_name) %>(payload, []) 
        end

        @doc \"\"\"
        Invokes the <%= method_name %> method registered on <%= @actor_name %>.

        ## Parameters
        - `ref` - The actor ref to send the action to.
        - `payload` - The payload to send to the action.
        - `opts` - The options to pass to the action.

        ## Examples
        ```elixir
        iex> <%= @module %>.<%= Macro.underscore(method_name) %>(SpawnSdk.Actor.ref("<%= @actor_system %>", "actor_id_01"), %<%= input %>{}, async: false, metadata: %{"example" => "metadata"})
        {:ok, %<%= output %>{}}
        ```
        \"\"\"
        def <%= Macro.underscore(method_name) %>(%SpawnSdk.ActorRef{} = ref, %<%= input %>{} = payload, opts) when is_list(opts) do
          opts = [
            system: ref.system || "<%= @actor_system %>",
            action: "<%= method_name %>",
            payload: payload,
            async: opts[:async] || false,
            metadata: opts[:metadata] || %{}
          ]

          actor_to_invoke = ref.name || "<%= @actor_name %>"

          opts = if actor_to_invoke == "<%= @actor_name %>" do
            opts
          else
            Keyword.put(opts, :ref, "<%= @actor_name %>")
          end

          SpawnSdk.invoke(actor_to_invoke, opts)
        end
      <% end %>
    end
    <% end %>
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: [_ | _] = svcs} = _desc) do
    svcs =
      Enum.filter(svcs, fn svc ->
        Map.get(svc.options || %{}, :__pb_extensions__, %{})
        |> Map.get({Spawn.Actors.PbExtension, :actor})
      end)

    do_generate(ctx, svcs)
  end

  def generate(_ctx, _opts), do: {"unknown", [render: false]}

  defp do_generate(_ctx, []), do: {"unknown", [render: false]}

  defp do_generate(ctx, svcs) do
    for svc <- svcs do
      mod_name = Util.mod_name(ctx, [Macro.camelize(svc.name)])
      actor_name = Macro.camelize(svc.name)
      actor_system = Config.get(:actor_system_name)

      methods =
        for m <- svc.method do
          input = Util.type_from_type_name(ctx, m.input_type)
          output = Util.type_from_type_name(ctx, m.output_type)

          options =
            m.options
            |> opts()
            |> inspect(limit: :infinity)

          {m.name, input, output, options}
        end

      {mod_name,
       [
         module: mod_name,
         actor_system: actor_system,
         actor_name: actor_name,
         service_name: mod_name,
         methods: methods,
         version: Util.version(),
         render: true
       ]}
    end
  end

  defp opts(nil), do: %{}

  defp opts(%Google.Protobuf.MethodOptions{__pb_extensions__: extensions})
       when extensions == %{} do
    %{}
  end

  defp opts(%Google.Protobuf.MethodOptions{__pb_extensions__: extensions}) do
    for {{type, field}, value} <- extensions, into: %{} do
      {field, %{type: type, value: value}}
    end
  end
end
