defmodule ActivatorSimple.Sources.Simple do
  use ActivatorSimple.Routes.Base

  alias Activator.Dispatcher.DefaultDispatcher, as: Dispatcher
  alias Io.Cloudevents.V1.CloudEvent

  @content_type "application/json"

  post "/system/:system_name/actors/:actor_name/actions/:action_name" do
    remote_ip = get_remote_ip(conn)

    opts =
      if is_nil(remote_ip) do
        [system: system_name, actor: actor_name, command: action_name]
      else
        [system: system_name, actor: actor_name, command: action_name, remote_ip: remote_ip]
      end

    # TODO use CloudEvent here
    case Dispatcher.dispatch(nil, opts) do
      :ok ->
        send!(conn, 202, %{status: "accepted"}, @content_type)

      error ->
        response_body = %{status: "Error on invoke Actor. #{inspect(error)}"}
        send!(conn, 500, response_body, @content_type)
    end
  end

  defp get_remote_ip(%{remote_ip: remote_ip}) when is_nil(remote_ip), do: nil

  defp get_remote_ip(%{remote_ip: remote_ip}), do: to_string(:inet_parse.ntoa(remote_ip))

  defp get_remote_ip(_conn), do: nil
end
