defmodule GistAshWeb.GistLive.Index do
  use GistAshWeb, :live_view
  use GistAshWeb, :verified_routes

  require Ash.Query

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:gists, [])
     |> assign(:page, 1)
     |> list_gists()}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    gist =
      GistAsh.Gists.Gist
      |> Ash.Query.filter(id == ^id)
      |> GistAsh.Gists.read!()

    first_gist = List.first(gist)

    related_files =
      GistAsh.Gists.File
      |> Ash.Query.filter(gist_id == ^first_gist.id)
      |> GistAsh.Gists.read!()

    Enum.each(related_files, fn file ->
      Ash.destroy(file, actor: socket.assigns.current_user)
    end)

    case Ash.destroy!(first_gist, actor: socket.assigns.current_user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Gist deleted successfully")
         |> list_gists()}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting gist")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Gists")
    |> assign(:gist, nil)
  end

  defp list_gists(socket) do
    page = socket.assigns.page
    gists = GistAsh.Gists.Gist
            |> Ash.Query.load(:files)
            |> Ash.Query.page(limit: 20, offset: (page - 1) * 20)
            |> GistAsh.Gists.read!()
    stream(socket, :gists, gists.results, reset: true)
  end
end
