defmodule SpawnCtl.Commands.New.Java do
  @moduledoc """
  Create template for the Java template.
  """
  use DoIt.Command,
    name: "java",
    description: "Generate a Spawn Java project."

  alias SpawnCtl.Util.Emoji
  alias Spawnctl.Cookiecutter
  alias SpawnCtl.Commands.New.Behavior.Runtime
  alias Spawnctl.Runtimes.Behaviors.UnixRuntime.New, as: UnixNewCommand
  alias Spawnctl.Runtimes.Behaviors.WindowsRuntime.New, as: WindowsNewCommand

  import SpawnCtl.Util, only: [log: 3]

  @vsn "2.0.0-RC5"
  @main_sdk_version "1.4.3"
  @template "java-std"

  @default_opts %{
    actor_system: "spawn-system",
    app_namespace: "default",
    app_description: "Spawn Java Standard App.",
    app_image_tag: "ttl.sh/spawn-java-example:1h",
    group_id: "io.eigr.spawn.java",
    artifact_id: "demo",
    statestore_user: "admin",
    statestore_pwd: "admin",
    statestore_key: "myfake-key-3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="
  }

  option(:actor_system, :string, "Spawn actor system.",
    alias: :s,
    default: @default_opts.actor_system
  )

  option(:app_namespace, :string, "Spawn ActorSystem namespace.",
    alias: :n,
    default: @default_opts.app_namespace
  )

  option(:app_description, :string, "Defines the application description.",
    alias: :d,
    default: @default_opts.app_description
  )

  option(:app_image_tag, :string, "Defines the OCI Container image tag.",
    alias: :t,
    default: @default_opts.app_image_tag
  )

  option(:sdk_version, :string, "Spawn Java SDK version.",
    alias: :v,
    default: @main_sdk_version,
    allowed_values: [
      @main_sdk_version,
      "1.4.2"
    ]
  )

  option(:template_version, :string, "Spawn CLI Language templates version.",
    alias: :T,
    default: "v#{@vsn}"
  )

  option(:statestore_type, :string, "Spawn statestore provider.",
    alias: :S,
    default: "native",
    allowed_values: [
      "mariadb",
      "postgres",
      "native"
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

  option(:group_id, :string, "Java project groupId.",
    alias: :g,
    default: @default_opts.group_id
  )

  option(:artifact_id, :string, "Java project artifactId.",
    alias: :a,
    default: @default_opts.artifact_id
  )

  option(:version, :string, "Java project version.",
    alias: :V,
    default: "1.0.1"
  )

  argument(:name, :string, "Name of the project to be created.")

  @doc """
  Executes the command to generate a new Spawn Java project.

  ## Parameters
  - `args`: A map containing the command arguments.
  - `opts`: A map containing the command options.
  - `context`: The context in which the command is executed.

  The `name` argument is used to create the project with the given name.
  """
  def run(args, opts, _context) do
    log(:info, Emoji.exclamation(), "Generating project for Java")

    opts
    |> prepare()
    |> render(args, opts)
    |> then(fn
      {:ok, template_path} ->
        case Cookiecutter.cleanup(template_path, @template, opts) do
          :ok ->
            log(:info, Emoji.check(), "Clean up done!")
            log(:info, Emoji.rocket(), "Project generated successfully")

          {:error, message} ->
            log(
              :error,
              Emoji.tired_face(),
              "Failure when trying to clean up resources. Details: #{inspect(message)}"
            )
        end

      {:error, message} ->
        log(:error, Emoji.exclamation(), message)
    end)
  end

  defp prepare(opts) do
    log(:info, Emoji.exclamation(), "Starting preparation phase...")

    case :os.type() do
      {:unix, _} ->
        %UnixNewCommand{opts: opts}
        |> Runtime.prepare(@template, fn
          {:ok, template_path} ->
            log(:info, Emoji.check(), "Preparation phase carried out successfully!")
            {:ok, template_path}

          {:error, message} ->
            log(:error, Emoji.winking(), "Failure in the preparation phase!")
            {:error, message}
        end)

      {:win32, _} ->
        %WindowsNewCommand{opts: opts}
        |> Runtime.prepare(@template, fn
          {:ok, template_path} ->
            {:ok, template_path}

          {:error, message} ->
            {:error, message}
        end)
    end
  end

  defp render({:error, message}, _args, _opts), do: {:error, message}

  defp render({:ok, template_path}, %{name: name} = _args, %{sdk_version: sdk_version} = opts)
       when not is_nil(sdk_version) do
    app_hyphenized_name = String.replace(name, "_", "-")

    statestore_type =
      if is_nil(opts.statestore_type) || opts.statestore_type == "" do
        "native"
      else
        opts.statestore_type
      end

    extra_context = %{
      "app_name" => name,
      "app_name_hyphenate" => app_hyphenized_name,
      "spawn_app_spawn_system" => opts.actor_system,
      "spawn_app_namespace" => opts.app_namespace,
      "spawn_app_statestore_type" => statestore_type,
      "spawn_sdk_version" => "v#{sdk_version}",
      "group_id" => opts.group_id,
      "artifact_id" => opts.artifact_id,
      "version" => opts.version,
      "app_image_tag" => opts.app_image_tag
    }

    do_render(template_path, extra_context)
  end

  defp render({:ok, template_path}, %{name: name} = _args, opts) do
    app_hyphenized_name = String.replace(name, "_", "-")

    statestore_type =
      if is_nil(opts.statestore_type) || opts.statestore_type == "" do
        "native"
      else
        opts.statestore_type
      end

    extra_context = %{
      "app_name" => name,
      "app_name_hyphenate" => app_hyphenized_name,
      "spawn_app_spawn_system" => opts.actor_system,
      "spawn_app_namespace" => opts.app_namespace,
      "spawn_app_statestore_type" => statestore_type,
      "spawn_sdk_version" => "v#{@main_sdk_version}",
      "group_id" => opts.group_id,
      "artifact_id" => opts.artifact_id,
      "version" => opts.version,
      "app_image_tag" => opts.app_image_tag
    }

    do_render(template_path, extra_context)
  end

  defp do_render(template_path, extra_context) do
    output_dir = File.cwd!()

    case Cookiecutter.generate_project(template_path, output_dir, extra_context) do
      {:ok, _output} ->
        {:ok, template_path}

      {:error, message} ->
        {:error, message}
    end
  end
end
