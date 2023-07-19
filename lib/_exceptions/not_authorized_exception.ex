defmodule Actors.Exceptions.NotAuthorizedException do
  @moduledoc """
  Error raised when the Actor understands the request but refuses to authorize it.

  This error should result in a http 403 status code.
  see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403
  """

  defexception plug_status: 403

  def message(_), do: "you have no rights to make this action."
end
