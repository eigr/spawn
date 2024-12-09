defmodule Eigr.Functions.Protocol.Actors.PbExtension do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.FieldOptions, :actor_id, 9999,
    optional: true,
    type: :bool,
    json_name: "actorId"
  )
end
