defmodule Operator.K8S.Manifest do
  @type name :: String.t()

  @type namespace :: String.t()

  @type params :: map()

  @type manifest :: map()

  @callback manifest(namespace(), name(), params()) :: manifest()
end
