defmodule Spawnctl.Cookiecutter do
  @moduledoc """
  A module to call the cookiecutter Python application from Elixir within a virtual environment.
  """
  alias SpawnCtl.Util.Emoji
  import SpawnCtl.Util, only: [log: 3]

  @venv_dir "#{File.cwd!()}/.venv"
  @cookiecutter_path "#{@venv_dir}/bin/cookiecutter"

  def generate_project(input_dir, output_dir, extra_context) do
    case setup_venv() do
      {:ok, _message} ->
        # Convert the extra context to a JSON string
        extra_context_args = convert_extra_context_to_args(extra_context)

        # Prepare the command arguments
        args =
          [
            input_dir,
            "-o",
            output_dir,
            "--no-input"
          ] ++ extra_context_args

        # Run the cookiecutter command
        log(:info, Emoji.runner(), "Generating project...")

        {output, exit_code} =
          System.cmd(@cookiecutter_path, args, stderr_to_stdout: true)

        if exit_code == 0 do
          {:ok, output}
        else
          {:error, output}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cleanup(template_path, lang, opts) do
    pwd = File.cwd!()
    tmp_file = Path.join(pwd, "#{lang}-v#{opts.sdk_version}.tar.gz")

    with {:drop_template_path, {:ok, _files}} <-
           {:drop_template_path, drop_template(template_path)},
         {:drop_venv_path, {:ok, _files}} <- {:drop_venv_path, drop_virtualenv(@venv_dir)},
         {:drop_pkg, :ok} <- {:drop_pkg, drop_pkgs(tmp_file)} do
      :ok
    else
      {:drop_template_path, {:error, detail, _file}} ->
        message = "Unable to delete some resources [#{detail}]"
        {:error, message}

      {:drop_venv_path, {:error, detail, _file}} ->
        message = "Unable to delete virtual environment [#{detail}]"
        {:error, message}

      {:drop_pkg, {:error, detail}} ->
        message = "Unable to delete pkgs [#{detail}]"
        {:error, message}

      error ->
        message = "Unknown [#{error}]"
        {:error, message}
    end
  end

  defp drop_template(template_path) do
    log(:info, Emoji.floppy_disk(), "Deleting temporary templating...")
    File.rm_rf(template_path)
  end

  defp drop_virtualenv(venv_dir) do
    log(:info, Emoji.floppy_disk(), "Deleting virtual environment...")
    File.rm_rf(venv_dir)
  end

  defp drop_pkgs(pkg_file) do
    log(:info, Emoji.floppy_disk(), "Deleting temporary packages...")
    File.rm(pkg_file)
  end

  defp convert_extra_context_to_args(extra_context) do
    Enum.flat_map(extra_context, fn {key, value} ->
      ["#{key}=#{value}"]
    end)
  end

  def setup_venv do
    case find_python_executable() do
      {:ok, python_executable} ->
        # Create virtual environment
        log(:info, Emoji.floppy_disk(), "Creating virtual environment to build template...")
        {output, exit_code} = System.cmd(python_executable, ["-m", "venv", @venv_dir])

        if exit_code == 0 do
          log(:info, Emoji.check(), "Virtual environment created successfully!")
          install_cookiecutter()
        else
          {:error, "Failed to create virtual environment: #{output}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_python_executable() do
    case System.find_executable("python3") do
      nil ->
        case System.find_executable("python") do
          nil -> {:error, "Python executable not found"}
          python_path -> {:ok, python_path}
        end

      python_path ->
        {:ok, python_path}
    end
  end

  defp install_cookiecutter do
    # Install cookiecutter in virtual environment
    {output, exit_code} =
      System.cmd("#{@venv_dir}/bin/pip", [
        "install",
        "--disable-pip-version-check",
        "cookiecutter"
      ])

    if exit_code == 0 do
      {:ok, "cookiecutter installed successfully"}
    else
      {:error, "Failed to install cookiecutter: #{output}"}
    end
  end
end
