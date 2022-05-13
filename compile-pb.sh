#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# CloudState Protocol

protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/spawn/actors --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/actor.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/spawn/actors --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/protocol.proto