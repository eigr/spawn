defmodule SpawnOperator.K8s.Plugins do
  @moduledoc false

  @type resource :: map()
  @type manifest :: map()
  @type opts :: Keyword.t()

  @callback manifest(resource(), opts()) :: {:ok, list(manifest())} | :error
end
