defmodule Activator do
  @moduledoc """
  Documentation for `Activator`.
  """

  def get_http_port(config), do: if(Mix.env() == :test, do: 0, else: config.http_port)
end
