defmodule Eigr.Functions.Protocol.Actors.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  extend(Google.Protobuf.FieldOptions, :actor_id, 9999,
    optional: true,
    type: :bool,
    json_name: "actorId"
  )
end
