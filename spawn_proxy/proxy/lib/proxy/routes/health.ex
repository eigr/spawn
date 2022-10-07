defmodule Proxy.Routes.Health do
  use Proxy.Routes.Base

  @content_type "application/json"

  get "/" do
    send!(conn, 200, %{status: "up"}, @content_type)
  end

  get "/liveness" do
    send!(conn, 200, %{status: "up"}, @content_type)
  end

  get "/readiness" do
    send!(conn, 200, %{status: "up"}, @content_type)
  end
end
