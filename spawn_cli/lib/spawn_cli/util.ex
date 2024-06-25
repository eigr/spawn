defmodule SpawnCli.Util do
  @moduledoc false

  def log(:info, emoji, msg), do: IO.puts(IO.ANSI.blue() <> "#{emoji}  " <> msg)
  def log(:error, emoji, msg), do: IO.puts(:stderr, IO.ANSI.red() <> "#{emoji}  " <> msg)

  defmodule Emoji do
    @moduledoc false

    def check(),
      do: Exmoji.find_by_short_name("x") |> List.first() |> Exmoji.EmojiChar.render()

    def exclamation(),
      do: Exmoji.find_by_short_name("exclamation") |> List.first() |> Exmoji.EmojiChar.render()

    def floppy_disk(),
      do: Exmoji.find_by_short_name("floppy_disk") |> List.first() |> Exmoji.EmojiChar.render()

    def hourglass(),
      do: Exmoji.find_by_short_name("hourglass") |> List.first() |> Exmoji.EmojiChar.render()

    def rocket(),
      do: Exmoji.find_by_short_name("rocket") |> List.first() |> Exmoji.EmojiChar.render()

    def ok(),
      do: Exmoji.find_by_short_name("ok") |> List.first() |> Exmoji.EmojiChar.render()

    def runner(),
      do: Exmoji.find_by_short_name("runner") |> List.first() |> Exmoji.EmojiChar.render()

    def sunglasses(),
      do: Exmoji.find_by_short_name("sunglasses") |> List.first() |> Exmoji.EmojiChar.render()

    def tired_face(),
      do: Exmoji.find_by_short_name("tired_face") |> List.first() |> Exmoji.EmojiChar.render()

    def winking(),
      do: Exmoji.find_by_short_name("winking") |> List.first() |> Exmoji.EmojiChar.render()
  end
end
