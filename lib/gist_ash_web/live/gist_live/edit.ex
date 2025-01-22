defmodule GistAshWeb.GistLive.Edit do
  use GistAshWeb, :live_view
  use GistAshWeb, :verified_routes

  require Ash.Query

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case GistAsh.Gists.Gist
         |> Ash.Query.filter(id == ^id)
         |> Ash.Query.load(:files)
         |> Ash.read() do
      {:ok, [gist]} ->
        form =
          AshPhoenix.Form.for_update(
            gist,
            :update,
            api: GistAsh.Gists,
            actor: socket.assigns.current_user,
            relationships: [files: [:filename, :content]]
          )
          |> to_form()

        files = Enum.map(gist.files, fn file ->
          %{"id" => file.id, "filename" => file.filename, "content" => file.content}
        end)

        {:ok,
         socket
         |> assign(:gist, gist)
         |> assign(:form, form)
         |> assign(:files, files)
         |> assign(:action, :edit)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Gist not found")
         |> push_navigate(to: ~p"/gists")}
    end
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    files =
      case form_params["files"] do
        nil -> []
        files when is_map(files) ->
          files
          |> Map.values()
          |> Enum.reject(fn file ->
            is_nil(file["filename"]) || file["filename"] == ""
          end)
          |> Enum.map(fn file ->
            if file["id"], do: Map.put(file, "id", file["id"]), else: file
          end)
      end

    # Ensure we always have at least one file
    files = if Enum.empty?(files), do: [%{"filename" => "", "content" => ""}], else: files

    params = %{
      "description" => form_params["description"],
      "public" => form_params["public"] == "true",
      "files" => files
    }

    changeset =
      socket.assigns.gist
      |> Ash.Changeset.for_update(:update, params,
        api: GistAsh.Gists,
        actor: socket.assigns.current_user,
        validate?: true,
        relationships: [files: [:filename, :content]]
      )

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("add-file", _, socket) do
    files = socket.assigns.files ++ [%{"filename" => "", "content" => ""}]
    {:noreply, assign(socket, :files, files)}
  end

  @impl true
  def handle_event("remove-file", %{"index" => index}, socket) do
    files = List.delete_at(socket.assigns.files, String.to_integer(index))
    {:noreply, assign(socket, :files, files)}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    files =
      case form_params["files"] do
        nil -> []
        files when is_map(files) ->
          files
          |> Map.values()
          |> Enum.reject(fn %{"filename" => filename} ->
            is_nil(filename) || filename == ""
          end)
      end

    if Enum.empty?(files) do
      {:noreply,
       socket
       |> put_flash(:error, "At least one file with a filename is required")
       |> assign_form(Ash.Changeset.for_update(socket.assigns.gist, :update, %{}))}
    else
      params = %{
        "description" => form_params["description"],
        "public" => form_params["public"] == "true",
        "files" => files
      }

      changeset =
        socket.assigns.gist
        |> Ash.Changeset.for_update(:update, params,
          api: GistAsh.Gists,
          actor: socket.assigns.current_user,
          relationships: [:files]
        )

      IO.inspect(changeset.data, label: "Changeset")

      case Ash.update(changeset, domain: GistAsh.Gists, actor: socket.assigns.current_user) do
        {:ok, gist} ->
          {:noreply,
           socket
           |> put_flash(:info, "Gist updated successfully")
           |> push_navigate(to: ~p"/gists/#{gist.id}")}

        {:error, changeset} ->
          IO.inspect(changeset.errors, label: "Changeset with errors")
          error_messages =
            changeset.errors
            |> Enum.map(fn {field, message} -> "#{field}: #{message}" end)
            |> Enum.join(", ")

          {:noreply,
            socket
            |> put_flash(:error, "Failed to update gist: #{error_messages}")
            |> assign_form(changeset)}
      end
    end
  end

  defp assign_form(socket, changeset) do
    form =
      AshPhoenix.Form.for_update(
        socket.assigns.gist,  # Pass the original gist struct here
        :update,
        api: GistAsh.Gists,
        actor: socket.assigns.current_user,
        changeset: changeset,  # Provide the existing changeset
        relationships: [:files]
      )
      |> to_form()

    assign(socket, :form, form)
  end
end
