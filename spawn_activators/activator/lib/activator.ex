defmodule Activator do
  @moduledoc """
  Documentation for `Activator`.
  """

  alias Actors.Config.PersistentTermConfig, as: Config

  def get_http_port(_opts), do: Config.get(:http_port)
end
