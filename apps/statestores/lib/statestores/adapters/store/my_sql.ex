defmodule Statestores.Adapters.Store.MySQL do
  use Ecto.Repo,
    otp_app: :statestores,
    adapter: Ecto.Adapters.MyXQL
end
