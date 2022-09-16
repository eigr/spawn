defmodule Actors.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Spawn.SandboxHelper, repos: [Statestores.Util.load_repo()]

      use Actors.MockTest
      import Actors.FactoryTest

      import Spawn.DataCase
    end
  end
end
