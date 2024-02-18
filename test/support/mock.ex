defmodule Actors.MockTest do
  @moduledoc false

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      alias Eigr.Functions.Protocol.ActorInvocationResponse

      setup do
        Agent.start_link(fn -> nil end, name: Actors.MockTest)

        :ok
      end

      def mock_invoke_host_actor_with_ok_response(response) do
        Agent.update(Actors.MockTest, fn _ -> response end)
      end
    end
  end
end
