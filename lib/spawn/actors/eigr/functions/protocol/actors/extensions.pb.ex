defmodule Eigr.Functions.Protocol.Actors.PbExtension do
  @moduledoc false
<<<<<<< HEAD
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
=======
  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3
>>>>>>> main

  extend(Google.Protobuf.FieldOptions, :actor_id, 9999,
    optional: true,
    type: :bool,
    json_name: "actorId"
  )
end
