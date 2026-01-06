defmodule Spawn do
  if Mix.env() == :prod do
    @moduledoc false
  else
    @moduledoc "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC !-->")
               |> Enum.fetch!(1)
  end
end
