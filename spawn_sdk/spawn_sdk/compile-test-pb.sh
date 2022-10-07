#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

protoc --elixir_out=gen_descriptors=true:./test/support/protos --proto_path=test/support/protos test/support/protos/my_actor.proto

