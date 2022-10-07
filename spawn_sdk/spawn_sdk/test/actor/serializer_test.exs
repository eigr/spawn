defmodule Actor.SerializerTest do
  use ExUnit.Case

  alias Eigr.Spawn.Actor.MyState
  alias Google.Protobuf.Any

  import Spawn.Utils.AnySerializer

  describe "encode" do
    test "encode user defined struct" do
      state = MyState.new(id: "1", value: 1)
      packed = any_pack!(state)

      assert "type.googleapis.com/eigr.spawn.actor.MyState" = packed.type_url
    end
  end

  describe "decode" do
    test "decode user defined struct" do
      state = MyState.new(id: "1", value: 1)
      packed = any_pack!(state)

      assert "type.googleapis.com/eigr.spawn.actor.MyState" = packed.type_url
      assert %MyState{} = any_unpack!(packed, Eigr.Spawn.Actor.MyState)
      assert %MyState{} = unpack_unknown(packed)
    end

    test "decode binary user defined struct" do
      state = MyState.new(id: "1", value: 1)
      packed = any_pack!(state)
      bin = Any.encode(packed)

      assert %MyState{} = unpack_any_bin(bin)
    end
  end
end
