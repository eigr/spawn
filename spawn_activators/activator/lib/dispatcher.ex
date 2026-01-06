defmodule Activator.Dispatcher do
  @moduledoc """
  `Dispatcher`
  """

  @type data ::
          Cloudevents.Format.V_1_0.Event.t()
          | Cloudevents.Format.V_0_2.Event.t()
          | Cloudevents.Format.V_0_1.Event.t()

  @type options() :: [option()]
  @type option ::
          {:encoder, encoder :: module()}
          | {:system, system :: String.t()}
          | {:actor, actor :: String.t()}
          | {:action, action :: String.t()}
          | {:kind, kind :: atom()}

  @callback dispatch(data, options) :: :ok | {:error, any()}
end
