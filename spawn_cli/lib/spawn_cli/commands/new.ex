defmodule SpawnCli.Commands.New do
  use DoIt.Command,
    name: "new",
    description: "Create new Spawn project with specifi target language"

  argument(:message, :string, "Say hello to...")

  option(:template, :string, "Hello message template",
    alias: :t,
    default: "Hello <%= @message %>!!!"
  )

  def run(%{message: message}, %{template: template}, _) do
    IO.puts(EEx.eval_string(template, assigns: [message: message]))
  end
end
