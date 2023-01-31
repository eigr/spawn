defmodule Statestores.Types.HMAC do
  @moduledoc false
  use Cloak.Ecto.HMAC, otp_app: :spawn_statestores

  def init(_config) do
    {:ok,
     [
       algorithm: :sha512,
       secret: decode_env!("SPAWN_STATESTORE_KEY")
     ]}
  end

  defp decode_env!(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
