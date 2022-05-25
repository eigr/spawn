defmodule Statestores.Adapters.MySQL do
  use Ecto.Repo,
    otp_app: :statestores,
    adapter: Ecto.Adapters.MyXQL

  def init(_type, config) do
    config = Keyword.put(config, :database, System.get_env("PROXY_DATABASE_NAME", "eigr-functions-db"))
    config = Keyword.put(config, :username, System.get_env("PROXY_DATABASE_USERNAME", "admin"))
    config = Keyword.put(config, :password, System.get_env("PROXY_DATABASE_SECRET", "admin"))
    config = Keyword.put(config, :hostname, System.get_env("PROXY_DATABASE_HOST", "localhost"))
    config = Keyword.put(config, :port, String.to_integer(System.get_env("PROXY_DATABASE_PORT", "3306")))

    {:ok, config}
  end
end
