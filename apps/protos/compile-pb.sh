#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true:./lib/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/any.proto
protoc --elixir_out=gen_descriptors=true:./lib/actors --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/actor.proto
protoc --elixir_out=gen_descriptors=true:./lib/services --twirp_elixir_out=./lib/services --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/protocol.proto