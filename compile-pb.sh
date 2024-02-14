#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/spawn/grpc --proto_path=priv/protos/grpc/ priv/protos/grpc/reflection/v1alpha/reflection.proto

protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/any.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/actor.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/protocol.proto
protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/state.proto

#protoc --elixir_out=gen_descriptors=true:./lib/spawn/cloudevents --proto_path=priv/protos/io/cloudevents/v1 priv/protos/io/cloudevents/v1/spec.proto