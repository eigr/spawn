defmodule NodeClientMock do
  @moduledoc """
  This module is used to mock the node http client.
  """
  alias Spawn.ActorInvocationResponse

  def invoke_host_actor(_payload, _opts \\ []) do
    response = Agent.get(Actors.MockTest, fn state -> state end)

    {:ok, %Finch.Response{body: ActorInvocationResponse.encode(response)}}
  end
end
