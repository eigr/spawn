defmodule ActivatorSQS.Routes.Base do
  defmacro __using__([]) do
    quote do
      use Plug.Router

      plug(Plug.Logger)

      plug(:match)

      plug(Plug.Parsers,
        parsers: [:json],
        json_decoder: Jason
      )

      plug(:dispatch)

      def send!(conn, code, data, content_type)
          when is_integer(code) and content_type == "application/json" do
        conn
        |> Plug.Conn.put_resp_content_type(content_type)
        |> send_resp(code, Jason.encode!(data))
      end

      def send!(conn, code, data, content_type) when is_atom(code) do
        code =
          case code do
            :ok -> 200
            :not_found -> 404
            :malformed_data -> 400
            :non_authenticated -> 401
            :forbidden_access -> 403
            :server_error -> 500
            :error -> 504
          end

        send!(conn, code, data, content_type)
      end
    end
  end
end
