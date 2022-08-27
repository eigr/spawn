defmodule Activator.Config do
  @callback load() :: map()

  @callback get(atom()) :: any()
end
