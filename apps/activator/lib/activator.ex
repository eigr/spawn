defmodule Activator do
  @moduledoc """
  Documentation for `Activator`.
  """

  def get_http_port(config), do: if(Mix.env() == :test, do: 0, else: config.http_port)

  defmodule Dispatcher do
    @type data ::
            Cloudevents.Format.V_1_0.Event.t()
            | Cloudevents.Format.V_0_2.Event.t()
            | Cloudevents.Format.V_0_1.Event.t()

    @callback dispatch(data, any(), any()) :: {:ok, term} | {:error, String.t()}
  end
end
