#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/actors/actor --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/actor.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/actors/actor --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/protocol.proto