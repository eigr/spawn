defmodule SpawnCtl.Commands.New.Elixir do
  @moduledoc """
  This module implements the command to generate a new Spawn Elixir project.

  It uses the `DoIt.Command` behaviour to define and run the command,
  providing various options for configuring the new project.

  ## Usage

      ./spawnctl new elixir [OPTIONS] <name>

  Generate a Spawn Elixir project.

  ### Arguments:
    - `name`: Name of the project to be created.

  ### Options:
    - `--help`: Print this help.
    - `-s`, `--actor-system`: Defines the name of the ActorSystem. (Default: "spawn-system")
    - `-d`, `--app-description`: Defines the application description. (Default: "Spawn App.")
    - `-t`, `--app-image-tag`: Defines the OCI Container image tag. (Default: "spawn-elixir-example:#{@vsn}")
    - `-t`, `--app-namespace`: Defines the Kubernetes namespace to install app. (Default: "default")
    - `-e`, `--elixir-version`: Defines the Elixir version. (Allowed Values: "1.14", "1.15", "1.16", "1.17")
    - `-v`, `--sdk-version`: Spawn Elixir SDK version. (Allowed Values: "#{@main_sdk_version}")
    - `-S`, `--statestore-type`: Spawn statestore provider. (Allowed Values: "cockroachdb", "mariadb", "mssql", "mysql", "postgres", "sqlite")
    - `-U`, `--statestore-user`: Spawn statestore username. (Default: "admin")
    - `-P`, `--statestore-pwd`: Spawn statestore password. (Default: "admin")
    - `-K`, `--statestore-key`: Spawn statestore key. (Default: "myfake-key")
  """
  use DoIt.Command,
    name: "elixir",
    description: "Generate a Spawn Elixir project."

  alias SpawnCtl.Util.Emoji
  alias Spawnctl.Cookiecutter
  alias SpawnCtl.Commands.New.Behavior.Runtime
  alias Spawnctl.Runtimes.Behaviors.UnixRuntime.New, as: UnixNewCommand
  alias Spawnctl.Runtimes.Behaviors.WindowsRuntime.New, as: WindowsNewCommand

  import SpawnCtl.Util, only: [log: 3]

  @vsn "1.4.1"
  @main_sdk_version "1.4.1"

  @default_opts %{
    actor_system: "spawn-system",
    app_description: "Spawn App.",
    app_image_tag: "spawn-elixir-example:#{@vsn}",
    app_namespace: "default",
    statestore_user: "admin",
    statestore_pwd: "admin",
    statestore_key: "myfake-key-3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="
  }

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: @default_opts.actor_system
  )

  option(:app_description, :string, "Defines the application description.",
    alias: :d,
    default: @default_opts.app_description
  )

  option(:app_image_tag, :string, "Defines the OCI Container image tag.",
    alias: :t,
    default: @default_opts.app_image_tag
  )

  option(:app_namespace, :string, "Defines the Kubernetes namespace to install app.",
    alias: :t,
    default: @default_opts.app_namespace
  )

  option(:elixir_version, :string, "Defines the Elixir version.",
    alias: :e,
    allowed_values: [
      "1.14",
      "1.15",
      "1.16",
      "1.17"
    ]
  )

  option(:sdk_version, :string, "Spawn Elixir SDK version.",
    alias: :v,
    allowed_values: [
      @main_sdk_version
    ]
  )

  option(:template_version, :string, "Spawn CLI Language templates version.",
    alias: :t,
    default: "v#{@vsn}"
  )

  option(:statestore_type, :string, "Spawn statestore provider.",
    alias: :S,
    allowed_values: [
      "cockroachdb",
      "mariadb",
      "mssql",
      "mysql",
      "postgres",
      "sqlite"
    ]
  )

  option(:statestore_user, :string, "Spawn statestore username.",
    alias: :U,
    default: @default_opts.statestore_user
  )

  option(:statestore_pwd, :string, "Spawn statestore password.",
    alias: :P,
    default: @default_opts.statestore_pwd
  )

  option(:statestore_key, :string, "Spawn statestore key.",
    alias: :K,
    default: @default_opts.statestore_key
  )

  argument(:name, :string, "Name of the project to be created.")

  @doc """
  Executes the command to generate a new Spawn Elixir project.

  ## Parameters
  - `args`: A map containing the command arguments.
  - `opts`: A map containing the command options.
  - `context`: The context in which the command is executed.

  The `name` argument is used to create the project with the given name.
  """
  def run(
        %{name: name} = _args,
        %{
          actor_system: actor_system,
          sdk_version: sdk_version
        } = opts,
        _context
      ) do
    app_module_name = Macro.camelize(name)
    app_hyphenized_name = String.replace(name, "_", "-")

    elixir_version =
      if is_nil(opts.elixir_version) || opts.elixir_version == "" do
        "1.14"
      else
        IO.inspect(opts.elixir_version, label: "Elixir Version")
        opts.elixir_version
      end

    statestore_type =
      if is_nil(opts.statestore_type) || opts.statestore_type == "" do
        "postgres"
      else
        IO.inspect(opts.statestore_type, label: "statestore_type")
        opts.statestore_type
      end

    opts
    |> prepare()
    |> then(fn
      {:ok, input_dir} ->
        output_dir = File.cwd!()
        IO.puts("Name of application: #{name}")

        extra_context = %{
          "elixir_version" => elixir_version,
          "app_name" => name,
          "app_description" => opts.app_description,
          "app_image_tag" => opts.app_image_tag,
          "app_module_name" => app_module_name,
          "app_name_hyphenate" => app_hyphenized_name,
          "app_port" => 8090,
          "spawn_app_spawm_system" => opts.actor_system,
          "spawn_app_namespace" => opts.app_namespace,
          "spawn_app_statestore_type" => statestore_type,
          "spawn_sdk_version" => opts.sdk_version
        }

        case Cookiecutter.generate_project(input_dir, output_dir, extra_context) do
          {:ok, output} ->
            IO.puts("Project generated successfully")
            IO.puts(output)

          {:error, message} ->
            log(:error, Emoji.exclamation(), message)
        end

      {:error, message} ->
        log(:error, Emoji.exclamation(), message)
    end)
  end

  defp prepare(opts) do
    case :os.type() do
      {:unix, _} ->
        %UnixNewCommand{opts: opts}
        |> Runtime.prepare("elixir", fn
          {:ok, template_path} ->
            {:ok, template_path}

          {:error, message} ->
            {:error, message}
        end)

      {:win32, _} ->
        %WindowsNewCommand{opts: opts}
        |> Runtime.prepare("elixir", fn
          {:ok, template_path} ->
            {:ok, template_path}

          {:error, message} ->
            {:error, message}
        end)
    end
  end
end
