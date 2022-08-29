defmodule Actors.Config do
  @callback load(module) :: map()

  @callback get(module, atom()) :: any()
end
