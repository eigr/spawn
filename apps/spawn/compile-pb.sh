#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/any.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/actor.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos/eigr/functions/protocol/actors priv/protos/eigr/functions/protocol/actors/protocol.proto

protoc --elixir_out=gen_descriptors=true:./lib/spawn/cloudevents --proto_path=priv/protos/io/cloudevents/v1 priv/protos/io/cloudevents/v1/spec.proto