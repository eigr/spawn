defmodule Actors.Security.Acl do
  @moduledoc """
  `Acl` is a acces control list helper module
  """
  alias Eigr.Functions.Protocol.InvocationRequest

  @type base_policies_path :: String.t()
  @type invocation :: InvocationRequest.t()
  @type policies :: list(AclPolicy.t())

  @callback get_policies!() :: policies()

  @callback load_acl_policies(base_policies_path()) :: policies()

  @callback is_authorized?(policies(), invocation()) :: boolean()

  defmodule Policy do
    defstruct name: nil, type: nil, actors: nil, actor_systems: nil, actions: nil

    @type t :: %__MODULE__{
            name: String.t(),
            type: String.t() | atom(),
            actors: list(String.t()),
            actor_systems: list(String.t()),
            actions: list(String.t())
          }
  end
end
