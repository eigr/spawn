defmodule Activator do
  @moduledoc """
  Documentation for `Activator`.
  """

  defmodule Dispatcher do
    @type data ::
            Cloudevents.Format.V_1_0.Event.t()
            | Cloudevents.Format.V_0_2.Event.t()
            | Cloudevents.Format.V_0_1.Event.t()

    @callback dispatch(data) :: {:ok, term} | {:error, String.t()}
  end

  def get_http_port(config), do: if(Mix.env() == :test, do: 0, else: config.http_port)
end
