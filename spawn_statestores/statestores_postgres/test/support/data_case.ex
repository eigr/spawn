defmodule Statestores.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Statestores.SandboxHelper, repos: [
       # Statestores.Util.load_snapshot_adapter(),
        Statestores.Util.load_projection_adapter(),
      ]

      import Statestores.DataCase
    end
  end
end
