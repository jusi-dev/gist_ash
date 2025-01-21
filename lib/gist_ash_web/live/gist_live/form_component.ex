defmodule GistAshWeb.GistLive.FormComponent do
  use GistAshWeb, :live_component

  @impl true
  def update(%{gist: gist} = assigns, socket) do
    changeset = Ash.Changeset.new(gist)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:files, [%{filename: "", content: ""}])
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"gist" => gist_params}, socket) do
    changeset =
      socket.assigns.gist
      |> Ash.Changeset.new()
      |> Ash.Changeset.cast(gist_params)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("add-file", _, socket) do
    files = socket.assigns.files ++ [%{filename: "", content: ""}]
    {:noreply, assign(socket, :files, files)}
  end

  @impl true
  def handle_event("remove-file", %{"index" => index}, socket) do
    files = List.delete_at(socket.assigns.files, String.to_integer(index))
    {:noreply, assign(socket, :files, files)}
  end

  @impl true
  def handle_event("save", %{"gist" => gist_params}, socket) do
    save_gist(socket, socket.assigns.action, gist_params)
  end

  defp save_gist(socket, :edit, params) do
    case socket.assigns.gist
         |> Ash.Changeset.new()
         |> Ash.Changeset.cast(params)
         |> GistAsh.Gists.update() do
      {:ok, gist} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gist updated successfully")
         |> push_patch(to: ~p"/gists/#{gist}")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error updating gist")
         |> assign_form(error)}
    end
  end

  defp save_gist(socket, :new, params) do
    files =
      socket.assigns.files
      |> Enum.with_index()
      |> Enum.map(fn {_, i} ->
        %{
          filename: params["file_#{i}_name"],
          content: params["file_#{i}_content"]
        }
      end)
      |> Enum.reject(& &1.filename == "")

    params = Map.put(params, "files", files)

    case GistAsh.Gists.create(params) do
      {:ok, gist} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gist created successfully")
         |> push_patch(to: ~p"/gists/#{gist}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ash.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
