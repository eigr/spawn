defmodule Proxy.Routes.API do
  use Proxy.Routes.Base

  alias Eigr.Functions.Protocol.Actors.Actor

  @content_type "application/octet-stream"

  post "/actorsystem" do
    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end

  post "/actorsystem/:name/actors/invoke" do
    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end

  post "/actorsystem/:name/actors/:actor_name/invoke" do
    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end
end
