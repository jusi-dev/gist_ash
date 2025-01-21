defmodule GistAshWeb.GistLive.Show do
  use GistAshWeb, :live_view
  import Ash.Query

  def mount(%{"id" => id}, _session, socket) do
    case GistAsh.Gists.Gist
         |> filter(id: id)
         |> load(:files)
         |> Ash.read() do
      {:ok, [gist]} ->
        {:ok,
         socket
         |> assign(:page_title, "Show Gist")
         |> assign(:gist, gist)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Gist not found")
         |> redirect(to: ~p"/gists")}
    end
  end
end
