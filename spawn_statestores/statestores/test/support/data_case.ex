defmodule Statestores.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Statestores.SandboxHelper, repos: [Statestores.Util.load_repo()]

      import Statestores.DataCase
    end
  end
end
