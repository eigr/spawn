defmodule SpawnCtl.ReadmeFetcher do
  @moduledoc false
  alias SpawnCtl.Util.Emoji

  import SpawnCtl.Util, only: [log: 3]

  @github_raw "https://raw.githubusercontent.com"

  def fetch_readme(owner, repo, path \\ "README.md") do
    url = "#{@github_raw}/#{owner}/#{repo}/main/#{path}"

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        render_and_print_readme(body)

      {:ok, %Req.Response{status: status}} ->
        log(
          :error,
          Emoji.tired_face(),
          "Failed to fetch README: HTTP status #{status}"
        )

        :error

      {:error, error} ->
        log(
          :error,
          Emoji.tired_face(),
          "Failed to fetch README: #{error}"
        )

        :error
    end
  end

  defp render_and_print_readme(readme_content) do
    case Earmark.as_html(readme_content) do
      {:ok, html, _} ->
        plain_text = html_to_plain_text(html)

        log(
          :info,
          Emoji.ok(),
          "Instructions:"
        )

        IO.puts(plain_text)

      {:error, _message, _context} ->
        log(
          :error,
          Emoji.tired_face(),
          "Failed to render markdown"
        )

        :error
    end
  end

  defp html_to_plain_text(html) do
    html
    |> String.replace(~r/<\/?[^>]+>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> String.replace("<br>", "\n")
    |> String.replace("<br />", "\n")
  end
end
