defmodule Statestores.Types.HMAC do
  @moduledoc false
  use Cloak.Ecto.HMAC, otp_app: :spawn_statestores

  alias Statestores.Util

  def init(_config) do
    {:ok,
     [
       algorithm: :sha512,
       secret: Util.get_statestore_key()
     ]}
  end
end
