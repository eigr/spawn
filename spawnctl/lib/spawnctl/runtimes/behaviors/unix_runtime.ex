defmodule Spawnctl.Runtimes.Behaviors.UnixRuntime do
  @moduledoc """
  Unix implementation of Commands
  """
  defmodule New do
    @moduledoc """

    """
    alias SpawnCtl.Util.Emoji
    alias Spawnctl.Runtimes.Behaviors.UnixRuntime.New, as: UnixNewCommand
    import SpawnCtl.Util, only: [extract_tar_gz: 1, log: 3]

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

        with {:download, {:ok, response}} <- {:download, download_pkg(template_project_url)},
             {:generate_temporary_data, :ok} <-
               {:generate_temporary_data, create_temporary_files!(tmp_file, response.body)},
             {:extract_files, {:ok, _response}} <-
               {:extract_files, extract_files!(pkg)} do
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

      def download_pkg(template_project_url) do
        log(:info, Emoji.runner(), "Downloading template package...")
        Req.get(template_project_url)
      end

      def create_temporary_files!(tmp_file, body) do
        log(:info, Emoji.floppy_disk(), "Saving template package on disk...")
        File.write!(tmp_file, body)
      end

      def extract_files!(pkg) do
        log(:info, Emoji.floppy_disk(), "Extracting template package...")
        extract_tar_gz(pkg)
      end
    end
  end
end
