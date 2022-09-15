defmodule Actors.Protos.ChangeNameStatusTest do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :OK, 0
  field :NAME_ALREADY_TAKEN, 1
end

defmodule Actors.Protos.StateTest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :name, 1, type: :string
  field :nickname, 2, type: :string
end

defmodule Actors.Protos.ChangeNameTest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :new_name, 1, type: :string
end

defmodule Actors.Protos.ChangeNameResponseTest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  field :status, 1, type: Actors.Protos.ChangeNameStatusTest, enum: true
  field :new_name, 2, type: :string
end
