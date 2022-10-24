defmodule Statestores.Vault do
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
