defmodule Spawnctl.Cookiecutter do
  @moduledoc """
  A module to call the cookiecutter Python application from Elixir within a virtual environment.
  """

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

  defp convert_extra_context_to_args(extra_context) do
    Enum.flat_map(extra_context, fn {key, value} ->
      ["#{key}=#{value}"]
    end)
  end

  def setup_venv do
    case find_python_executable() do
      {:ok, python_executable} ->
        # Create virtual environment
        {output, exit_code} = System.cmd(python_executable, ["-m", "venv", @venv_dir])

        if exit_code == 0 do
          IO.puts("Virtual environment created successfully")
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
    {output, exit_code} = System.cmd("#{@venv_dir}/bin/pip", ["install", "cookiecutter"])

    if exit_code == 0 do
      {:ok, "cookiecutter installed successfully"}
    else
      {:error, "Failed to install cookiecutter: #{output}"}
    end
  end
end
