defmodule Actors.Config do
  @moduledoc """
  `Config` defines methods that allow recovery of system settings
  """

  @callback load(module) :: map()

  @callback get(module, atom()) :: any()
end
