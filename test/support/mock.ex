defmodule Actors.MockTest do
  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      use Mimic

      setup :set_mimic_global

      alias Eigr.Functions.Protocol.ActorInvocationResponse

      def mock_invoke_host_actor_with_ok_response(response) do
        Actors.Node.Client
        |> stub(:invoke_host_actor, fn _payload ->
          {:ok, %Tesla.Env{body: ActorInvocationResponse.encode(response)}}
        end)
      end
    end
  end
end
