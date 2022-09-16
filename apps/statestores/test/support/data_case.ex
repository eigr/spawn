defmodule Statestores.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Spawn.SandboxHelper, repos: [Statestores.Util.load_repo()]

      import Spawn.DataCase
    end
  end
end
