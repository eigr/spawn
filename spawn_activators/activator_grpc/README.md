# Activator GRPC

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `activator_grpc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:activator_grpc, "~> 0.5.4"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/activator_grpc>.

# Compile protos

```shell
protoc --descriptor_set_out=priv/example/out/user-api.desc \
    --proto_path=priv/protos priv/protos/service.proto \
    --elixir_out=gen_descriptors=true:./priv/example/out # elixir_out or another language protoc plugin
```

```elixir
entities = [%{service_name: "io.eigr.spawn.example.TestService"}]
config = %{entities: entities, proto_file_path: "priv/example/out/user-api.desc", proto: nil}
ActivatorGrpc.Api.Discovery.discover(config)
```