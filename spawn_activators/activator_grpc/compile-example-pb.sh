#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Compile Protobuf HTTP protos
#protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/protobuf --proto_path=priv/protos/google/ priv/protos/google/protobuf/descriptor.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/activator_grpc/protobuf/api --proto_path=priv/protos/google/api/ priv/protos/google/api/http.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/activator_grpc/protobuf/api --proto_path=priv/protos/google/api/ priv/protos/google/api/annotations.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/activator_grpc/protobuf/api --proto_path=priv/protos/google/api/ priv/protos/google/api/httpbody.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/activator_grpc/protobuf/api --proto_path=priv/protos/google/api/ priv/protos/google/api/auth.proto
protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/activator_grpc/protobuf/api --proto_path=priv/protos/google/api/ priv/protos/google/api/source_info.proto

protoc --descriptor_set_out=priv/example/out/user-api.desc \
    --proto_path=priv/protos priv/protos/service.proto \
    --elixir_out=gen_descriptors=true,plugins=grpc:./priv/example/out 