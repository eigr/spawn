defmodule Activators do
  @moduledoc """
  Documentation for `Activators`.
  """

  defmodule Dispatcher do
    @type data ::
            Cloudevents.Format.V_1_0.Event.t()
            | Cloudevents.Format.V_0_2.Event.t()
            | Cloudevents.Format.V_0_1.Event.t()

    @callback dispatch(data) :: {:ok, term} | {:error, String.t()}
  end
end
