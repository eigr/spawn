defmodule Actors.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Statestores.SandboxHelper, repos: [Statestores.Util.load_snapshot_adapter()]

      use Actors.MockTest
      import Actors.FactoryTest

      import Actors.DataCase
    end
  end
end
