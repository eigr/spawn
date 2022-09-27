defmodule SpawnSdk.System.Supervisor do
  @moduledoc """
  Documentation for `System.Supervisor`.

  Start Supervisor tree like this:

    defmodule MyApp.Application do
      use Application

      @impl true
      def start(_type, _args) do
        children = [
          {
            SpawnSdk.System.Supervisor,
            system: "my-system", actors: [MyActor]
          }
        ]

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
    end
  """
  use Supervisor

  @impl true
  def init(state) do
    children = [
      {SpawnSdk.System.SpawnSystem, state}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(state) do
    Supervisor.start_link(
      __MODULE__,
      state,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
