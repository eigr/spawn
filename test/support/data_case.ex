defmodule Actors.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      if Statestores.Util.load_snapshot_adapter() != Statestores.Adapters.NativeSnapshotAdapter do
        use Statestores.SandboxHelper, repos: [Statestores.Util.load_snapshot_adapter()]
      end

      use Actors.MockTest
      import Actors.FactoryTest
      import Spawn.DistributedHelpers

      import Actors.DataCase
    end
  end
end
