#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

#protoc --elixir_out=gen_descriptors=true,plugins=grpc:./lib/spawn/grpc --proto_path=priv/protos/grpc/ priv/protos/grpc/reflection/v1alpha/reflection.proto

# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/any.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/empty.proto
# protoc --elixir_out=./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/descriptor.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/duration.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/timestamp.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/struct.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/source_context.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/field_mask.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/google/protobuf --proto_path=priv/protos/google/protobuf priv/protos/google/protobuf/wrappers.proto

# protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/extensions.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/actor.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/protocol.proto
# protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/state.proto


#protoc --elixir_out=gen_descriptors=true:./lib/spawn/actors --proto_path=priv/protos priv/protos/eigr/functions/protocol/actors/healthcheck.proto

#protoc --elixir_out=gen_descriptors=true:./lib/spawn/cloudevents --proto_path=priv/protos/io/cloudevents/v1 priv/protos/io/cloudevents/v1/spec.proto

PROTOS=("
    priv/protos/eigr/functions/protocol/actors/extensions.proto 
    priv/protos/eigr/functions/protocol/actors/actor.proto 
    priv/protos/eigr/functions/protocol/actors/protocol.proto 
    priv/protos/eigr/functions/protocol/actors/state.proto 
    priv/protos/eigr/functions/protocol/actors/healthcheck.proto
")

BASE_PATH=`pwd`

echo "Base protobuf path is: $BASE_PATH/priv/protos"

for file in $PROTOS; do
  echo "Compiling file $BASE_PATH/$file..."

  mix protobuf.generate \
    --output-path=./lib/spawn/actors \
    --include-docs=true \
    --generate-descriptors=true \
    --include-path=$BASE_PATH/priv/protos/ \
    --include-path=./priv/protos/google/protobuf \
    --include-path=./priv/protos/google/api \
    --plugin=ProtobufGenerate.Plugins.GRPCWithOptions \
    --one-file-per-module \
    $BASE_PATH/$file
done

