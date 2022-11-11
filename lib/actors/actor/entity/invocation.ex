defmodule Actors.Actor.Entity.Invocation do
  @moduledoc """
  Handles Invocation functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger

  alias Actors.Actor.Entity.EntityState

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSystem,
    Command,
    FixedTimerCommand
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    Broadcast,
    Context,
    Forward,
    InvocationRequest,
    Pipe,
    SideEffect,
    Workflow,
    Noop
  }

  alias Phoenix.PubSub

  @http_host_interface Actors.Actor.Interface.Http
  @host_interface_map %{
    "sdk" => SpawnSdk.Interface,
    "http" => @http_host_interface,
    "default" => @http_host_interface
  }

  @default_methods [
    "get",
    "Get",
    "get_state",
    "getState",
    "GetState"
  ]

  def timer_invoke(
        %FixedTimerCommand{command: %Command{name: cmd} = _command} = timer,
        %EntityState{
          system: _actor_system,
          actor: %Actor{id: caller_actor_id} = actor
        } = state
      ) do
    invocation = %InvocationRequest{
      actor: actor,
      command_name: cmd,
      payload: {:noop, Noop.new()},
      async: true,
      caller: caller_actor_id
    }

    invoke_result = invoke({invocation, []}, state)

    :ok = handle_timers([timer])

    case invoke_result do
      {:reply, _res, state} -> {:noreply, state}
      {:reply, _res, state, opts} -> {:noreply, state, opts}
    end
  end

  def handle_timers(timers) when is_list(timers) do
    if length(timers) > 0 do
      timers
      |> Stream.map(fn %FixedTimerCommand{seconds: delay} = timer_command ->
        Process.send_after(self(), {:invoke_timer_command, timer_command}, delay)
      end)
      |> Stream.run()
    end

    :ok
  catch
    error -> Logger.error("Error on handle timers #{inspect(error)}")
  end

  def handle_timers(nil), do: :ok

  def handle_timers([]), do: :ok

  def broadcast_invoke(
        command,
        payload,
        %ActorInvocation{actor_name: caller_actor_name, actor_system: actor_system},
        %EntityState{
          system: _actor_system,
          actor: %Actor{id: %ActorId{name: actor_name} = _id} = actor
        } = state
      ) do
    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event [#{inspect(payload)}] to perform Action [#{command}]"
    )

    invocation = %InvocationRequest{
      actor: actor,
      command_name: command,
      payload: payload,
      async: true,
      caller: ActorId.new(name: caller_actor_name, system: actor_system)
    }

    case invoke({invocation, []}, state) do
      {:reply, _res, state} -> {:noreply, state}
      {:reply, _res, state, opts} -> {:noreply, state, opts}
    end
  end

  def broadcast_invoke(
        payload,
        %EntityState{
          system: _actor_system,
          actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor
        } = state
      ) do
    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event [#{inspect(payload)}] without command. Just ignoring"
    )

    {:noreply, state}
  end

  @doc """
  Invoke function, receives a request and calls invoke host with the response
  """
  def invoke(
        {%InvocationRequest{
           actor:
             %Actor{
               id: %ActorId{name: actor_name} = _id
             } = _actor,
           metadata: metadata,
           command_name: command,
           payload: payload,
           caller: caller
         }, _opts},
        %EntityState{
          system: actor_system,
          actor: %Actor{state: actor_state, commands: commands, timer_commands: timers}
        } = state
      ) do
    if length(commands) <= 0 do
      Logger.warning("Actor [#{actor_name}] has not registered any Actions")
    end

    all_commands =
      commands ++ Enum.map(timers, fn %FixedTimerCommand{command: cmd} = _timer_cmd -> cmd end)

    case Enum.member?(@default_methods, command) or
           Enum.any?(all_commands, fn cmd -> cmd.name == command end) do
      true ->
        interface = get_interface(actor_system)

        metadata = if is_nil(metadata), do: %{}, else: metadata
        current_state = Map.get(actor_state || %{}, :state)

        request =
          ActorInvocation.new(
            actor_name: actor_name,
            actor_system: actor_system,
            command_name: command,
            payload: payload,
            current_context:
              Context.new(
                metadata: metadata,
                caller: caller,
                self: ActorId.new(name: actor_name, system: actor_system),
                state: current_state
              ),
            caller: caller
          )

        interface.invoke_host(request, state, @default_methods)
        |> case do
          {:ok, response, state} -> {:reply, {:ok, do_response(request, response, state)}, state}
          {:error, reason, state} -> {:reply, {:error, reason}, state, :hibernate}
        end

      false ->
        {:reply, {:error, "Command [#{command}] not found for Actor [#{actor_name}]"}, state,
         :hibernate}
    end
  end

  defp do_response(_request, %ActorInvocationResponse{workflow: workflow} = response, _state)
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_response(request, response, state) do
    do_run_workflow(request, response, state)
  end

  defp do_run_workflow(_request, %ActorInvocationResponse{workflow: workflow} = response, _state)
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_run_workflow(
         request,
         %ActorInvocationResponse{
           workflow: %Workflow{broadcast: broadcast, effects: effects} = _workflow
         } = response,
         _state
       ) do
    do_side_effects(effects)
    do_broadcast(request, broadcast)
    do_handle_routing(request, response)
  end

  defp do_handle_routing(
         _request,
         %ActorInvocationResponse{
           workflow: %Workflow{routing: routing} = _workflow
         } = response
       )
       when is_nil(routing),
       do: response

  defp do_handle_routing(
         %ActorInvocation{
           actor_name: caller_actor_name,
           actor_system: system_name
         },
         %ActorInvocationResponse{
           payload: payload,
           workflow:
             %Workflow{
               routing: {:pipe, %Pipe{actor: actor_name, command_name: cmd} = _pipe} = _workflow
             } = response
         }
       ) do
    invocation = %InvocationRequest{
      system: %ActorSystem{name: system_name},
      actor: %Actor{id: ActorId.new(name: actor_name, system: system_name)},
      command_name: cmd,
      payload: payload,
      caller: ActorId.new(name: caller_actor_name, system: system_name)
    }

    try do
      case Actors.invoke(invocation, []) do
        {:ok, response} -> response
        error -> error
      end
    catch
      error ->
        Logger.warning(
          "Error during Pipe request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
        )

        response
    end
  end

  defp do_handle_routing(
         %ActorInvocation{
           actor_system: system_name,
           payload: payload,
           actor_name: caller_actor_name
         } = _request,
         %ActorInvocationResponse{
           workflow:
             %Workflow{
               routing:
                 {:forward, %Forward{actor: actor_name, command_name: cmd} = _pipe} = _workflow
             } = response
         }
       ) do
    invocation = %InvocationRequest{
      system: %ActorSystem{name: system_name},
      actor: %Actor{id: ActorId.new(name: actor_name, system: system_name)},
      command_name: cmd,
      payload: payload,
      caller: ActorId.new(name: caller_actor_name, system: system_name)
    }

    try do
      case Actors.invoke(invocation, []) do
        {:ok, response} -> response
        error -> error
      end
    catch
      error ->
        Logger.warning(
          "Error during Forward request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
        )

        response
    end
  end

  def do_broadcast(_request, broadcast) when is_nil(broadcast) or broadcast == %{} do
    :ok
  end

  def do_broadcast(
        request,
        %Broadcast{channel_group: channel, command_name: command, payload: payload} = _broadcast
      ) do
    publish(channel, command, payload, request)
  end

  defp publish(channel, command, payload, _request) when is_nil(command) do
    PubSub.broadcast(
      :actor_channel,
      channel,
      {:receive, payload}
    )
  end

  defp publish(channel, command, payload, request) do
    PubSub.broadcast(
      :actor_channel,
      channel,
      {:receive, command, payload, request}
    )
  end

  def do_side_effects(effects) when is_list(effects) and effects == [] do
    :ok
  end

  def do_side_effects(effects) when is_list(effects) do
    spawn(fn ->
      effects
      |> Flow.from_enumerable(min_demand: 1, max_demand: System.schedulers_online())
      |> Flow.map(fn %SideEffect{
                       request:
                         %InvocationRequest{
                           actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor,
                           system: %ActorSystem{name: system_name}
                         } = invocation
                     } ->
        try do
          Actors.invoke(invocation, [])
        catch
          error ->
            Logger.warning(
              "Error during Side Effect request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
            )

            :ok
        end
      end)
      |> Flow.run()
    end)
  catch
    error ->
      Logger.warning("Error during Side Effect request. Error: #{inspect(error)}")
      :ok
  end

  defp get_interface(system_name) do
    if :persistent_term.get(system_name, false) do
      @host_interface_map["sdk"]
    else
      System.get_env("PROXY_HOST_INTERFACE", @host_interface_map["default"])
    end
  end
end
