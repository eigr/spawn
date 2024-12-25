#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

BASE_PATH=`pwd`

echo "Base protobuf path is: $BASE_PATH/priv/protos"

mix protobuf.generate \
  --output-path=./lib/_generated \
  --include-docs=true \
  --generate-descriptors=true \
  --include-path=$BASE_PATH/priv/protos/ \
  --include-path=./priv/protos/google/api \
  --plugin=ProtobufGenerate.Plugins.GRPCWithOptions \
  --one-file-per-module \
  $BASE_PATH/priv/protos/**/*.proto
