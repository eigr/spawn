defmodule Spawnctl.Runtimes.Behaviors.UnixRuntime do
  @moduledoc """
  Unix implementation of Commands
  """
  defmodule New do
    @moduledoc """

    """
    alias Spawnctl.Runtimes.Behaviors.UnixRuntime.New, as: UnixNewCommand
    import SpawnCtl.Util, only: [extract_tar_gz: 1]

    defstruct opts: %{}

    defimpl SpawnCtl.Commands.New.Behavior.Runtime, for: __MODULE__ do
      @impl true
      def prepare(%UnixNewCommand{opts: opts} = _strategy, lang, callback)
          when is_function(callback, 1) do
        template_project_url =
          "https://github.com/eigr/spawn-templates/releases/download/#{opts.template_version}/#{lang}-v#{opts.sdk_version}.tar.gz"

        pwd = File.cwd!()
        pkg = "#{pwd}/#{lang}-v#{opts.sdk_version}.tar.gz"
        tmp_file = Path.join(pwd, "#{lang}-v#{opts.sdk_version}.tar.gz")

        with {:download, {:ok, response}} <- {:download, Req.get(template_project_url)},
             {:generate_temporary_data, :ok} <-
               {:generate_temporary_data, File.write!(tmp_file, response.body)},
             {:extract_files, {:ok, response}} <-
               {:extract_files, extract_tar_gz(pkg)} do
          callback.({:ok, "#{pwd}/#{lang}"})
        else
          {:download, error} ->
            message = "Error during download. Details: #{inspect(error)}"
            callback.({:error, message})

          {:generate_temporary_data, error} ->
            message = "Error during creation of temporary files. Details: #{inspect(error)}"
            callback.({:error, message})

          {:extract_files, error} ->
            message = "Error during extract artifacts. Details: #{inspect(error)}"
            callback.({:error, message})

          error ->
            message = "Unknown error. Details: #{inspect(error)}"
            callback.({:error, message})
        end
      end
    end
  end
end
