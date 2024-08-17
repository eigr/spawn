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

  @default_opts %{
    actor_system: "spawn-system"
  }

  @vsn "1.4.2"
  @main_sdk_version "1.4.2"
  @template "java-std"

  option(:actor_system, :string, "Spawn actor system.",
    alias: :s,
    default: @default_opts.actor_system
  )

  option(:template_version, :string, "Spawn CLI Language templates version.",
    alias: :t,
    default: "v#{@vsn}"
  )

  option(:sdk_version, :string, "Spawn Java SDK version.",
    alias: :v,
    default: @main_sdk_version,
    allowed_values: [@main_sdk_version]
  )

  option(:group_id, :string, "Java project groupId.",
    alias: :g,
    default: "io.eigr.spawn.java"
  )

  option(:artifact_id, :string, "Java project artifactId.",
    alias: :a,
    default: "demo"
  )

  option(:version, :string, "Java project version.",
    alias: :V,
    default: "1.0.1"
  )

  option(:package, :string, "Java project package name.",
    alias: :p,
    default: "io.eigr.spawn.java.demo"
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
    extra_context = %{
      "app_name" => name,
      "spawn_system" => opts.actor_system,
      "sdk_version" => sdk_version,
      "group_id" => opts.group_id,
      "artifact_id" => opts.artifact_id,
      "version" => opts.version,
      "package" => opts.package
    }

    do_render(template_path, extra_context)
  end

  defp render({:ok, template_path}, %{name: name} = _args, opts) do
    extra_context = %{
      "app_name" => name,
      "spawn_system" => opts.actor_system,
      "sdk_version" => @main_sdk_version,
      "group_id" => opts.group_id,
      "artifact_id" => opts.artifact_id,
      "version" => opts.version,
      "package" => opts.package
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
