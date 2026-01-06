defmodule Activator do
  @moduledoc """
  Documentation for `Activator`.
  """

  alias Actors.Config.PersistentTermConfig, as: Config

  def get_http_port(_opts), do: Config.get(:http_port)

  def read_config_from_file(file_path) do
    case File.read(file_path) do
      {:ok, file_content} ->
        case Jason.decode(file_content) do
          {:ok, json_data} ->
            {:ok, json_data}

          {:error, reason} ->
            {:error, "Failed to parse JSON config file #{file_path}. Reason: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end
end
