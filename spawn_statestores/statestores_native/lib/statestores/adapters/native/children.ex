defmodule Statestores.Adapters.Native.Children do
  @moduledoc false

  def get_children do
    [
      Statestores.Adapters.Native.CustomMnesiacSupervisor
    ]
  end
end
