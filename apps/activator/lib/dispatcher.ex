defmodule Activator.Dispatcher do
  @moduledoc """
  `Dispatcher`
  """
  @type encoder :: module()

  @type data ::
          Cloudevents.Format.V_1_0.Event.t()
          | Cloudevents.Format.V_0_2.Event.t()
          | Cloudevents.Format.V_0_1.Event.t()

  @callback dispatch(encoder, data, any(), any()) :: :ok | {:error, any()}
end
