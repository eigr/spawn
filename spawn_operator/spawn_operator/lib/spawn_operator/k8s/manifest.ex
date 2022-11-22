defmodule SpawnOperator.K8s.Manifest do
  @type resource :: map()
  @type manifest :: map()

  @callback manifest(resource()) :: manifest()
end
