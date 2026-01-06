# Activator GRPC

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `activator_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:activator_api, "~> 0.6.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/activator_api>.

# Compile protos

```shell
protoc --descriptor_set_out=priv/example/out/user-api.desc \
    --proto_path=priv/protos priv/protos/service.proto \
    --elixir_out=gen_descriptors=true:./priv/example/out # elixir_out or another language protoc plugin
```

Create a kubernetes secrets containing the descriptor file created above.

```shell
kubectl -n default create secret generic protobuf-file-descriptors-secret --from-file=description=priv/example/out/user-api.desc
```

```elixir
entities = [%{service_name: "io.eigr.spawn.example.TestService"}]
config = %{entities: entities, proto_file_path: "priv/example/out/user-api.desc", proto: nil}
ActivatorAPI.Api.Discovery.discover(config)
```