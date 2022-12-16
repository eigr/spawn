defmodule SpawnOperator.K8s.Manifest do
  @type resource :: map()
  @type manifest :: map()
  @type opts :: Keyword.t()

  @callback manifest(resource(), opts()) :: manifest()
end
