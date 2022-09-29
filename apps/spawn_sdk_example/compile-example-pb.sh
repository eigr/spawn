#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true:./lib/spawn_sdk_example --proto_path=priv/protos priv/protos/example.proto

