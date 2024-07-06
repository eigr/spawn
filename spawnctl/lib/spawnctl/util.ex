defmodule SpawnCtl.Util do
  @moduledoc false

  @extension_blacklist ~w(.swp .swx)

  def extract_tar_gz(file_path) do
    current_path = File.cwd!()
    tar_command = "tar -xzf #{file_path} -C #{current_path}"

    case System.cmd("sh", ["-c", tar_command], stderr_to_stdout: true) do
      {output, 0} ->
        IO.puts(output)
        {:ok, "File extracted successfully"}

      {output, exit_code} ->
        {:error, "Failed to extract file, exit code: #{exit_code}, output: #{output}"}
    end
  end

  def is_valid?(file) do
    ext =
      file
      |> Path.extname()
      |> String.downcase()

    cond do
      String.last(file) == "~" ->
        false

      ext == "" ->
        false

      Enum.member?(@extension_blacklist, ext) ->
        false

      true ->
        true
    end
  end

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
