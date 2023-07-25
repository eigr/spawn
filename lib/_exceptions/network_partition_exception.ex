defmodule Actors.Exceptions.NetworkPartitionException do
  @moduledoc """
  Error raised when the Actor already activated on another node.
  """

  defexception plug_status: 409

  def message(_),
    do:
      "Unable to initialize the Actor because it is active on another Node or failed to update its status during a previous deactivation."
end
