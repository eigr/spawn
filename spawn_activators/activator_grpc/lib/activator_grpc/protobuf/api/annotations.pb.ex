defmodule Google.Api.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  extend Google.Protobuf.MethodOptions, :http, 72_295_728, optional: true, type: HttpRule
end
