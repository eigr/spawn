defmodule SpawnInitializer do
  @moduledoc """
  Documentation for `SpawnInitializer`.
  """
  use Bakeware.Script

  require Logger

  alias SpawnInitializer.Tls.Initializer

  @impl Bakeware.Script
  def main(args) do
    {[
       environment: environment,
       secret: secret,
       namespace: namespace,
       service: service,
       to: to
     ], _1,
     _2} =
      _opts =
      OptionParser.parse(args,
        switches: [
          environment: :string,
          secret: :string,
          namespace: :string,
          service: :string,
          to: :string
        ]
      )

    Logger.debug("Args: #{inspect(args)}")

    case Initializer.bootstrap_tls(
           String.to_atom(environment),
           secret,
           namespace,
           service,
           to
         ) do
      {:ok, _ca_bundle} ->
        0

      _ ->
        1
    end
  end
end
