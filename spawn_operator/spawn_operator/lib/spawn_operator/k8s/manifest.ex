defmodule SpawnOperator.K8s.Manifest do
  @type system :: String.t()

  @type name :: String.t()

  @type namespace :: String.t()

  @type params :: map()

  @type manifest :: map()

  @callback manifest(system(), namespace(), name(), params()) :: manifest()
end
