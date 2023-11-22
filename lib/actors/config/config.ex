defmodule Actors.Config do
  @moduledoc """
  `Config` defines methods that allow recovery of system settings
  """

  @callback load() :: map()

  @callback get(atom()) :: any()
end
