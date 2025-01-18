defmodule SpawnOperator.Utils do
  @moduledoc false

  def to_bool("false"), do: false
  def to_bool("true"), do: true
  def to_bool(_), do: false
end
