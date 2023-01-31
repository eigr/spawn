defmodule Statestores.Vault do
  @moduledoc """
  This module enables encryption on the database.
  See the Cloak and Cloak Ecto libraries documentation for more information.
  https://hexdocs.pm/cloak/readme.html
  https://hexdocs.pm/cloak_ecto/readme.html
  """
  use Cloak.Vault, otp_app: :spawn_statestores

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default:
          {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("SPAWN_STATESTORE_KEY")},
        secondary:
          {Cloak.Ciphers.AES.CTR, tag: "AES.CTR.V1", key: decode_env!("SPAWN_STATESTORE_KEY")}
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
