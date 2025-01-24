defmodule GistAshWeb.GistLive.New do
	use GistAshWeb, :live_view
	use GistAshWeb, :verified_routes

	@impl true
  def mount(_params, _session, socket) do
    initial_data = %{
      files: [%{"filename" => "", "content" => ""}]
    }

		form =
			AshPhoenix.Form.for_create(
				GistAsh.Gists.Gist,
				:create,
				api: GistAsh.Gists,
				actor: socket.assigns.current_user,
        relationships: [:files],
        data: initial_data
			)
			|> to_form()

		{:ok,
			socket
			|> assign(:form, form)
			|> assign(:files, [%{"filename" => "", "content" => ""}])
			|> assign(:action, :new)}
	end

	@impl true
	def handle_event("validate", %{"form" => form_params} = _params, socket) do
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

		# Ensure we always have at least one file
		files = if Enum.empty?(files), do: [%{"filename" => "", "content" => ""}], else: files

		params = %{
			"description" => form_params["description"],
			"public" => form_params["public"] == "true",
			"files" => files
		}

		changeset =
			GistAsh.Gists.Gist
			|> Ash.Changeset.for_create(:create, params,
				api: GistAsh.Gists,
				actor: socket.assigns.current_user,
				validate?: true,
				relationships: [:files]
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
		params = %{
			"description" => form_params["description"],
			"public" => form_params["public"] == "true",
			"files" => form_params["files"] |> Map.values(),
			"user_id" => socket.assigns.current_user.id
		}

		IO.inspect(socket.assigns.current_user.id, label: "Current user")
		IO.inspect(params, label: "Save Params")

		changeset =
			GistAsh.Gists.Gist
			|> Ash.Changeset.for_create(:create, params,
				api: GistAsh.Gists,
				actor: socket.assigns.current_user,
				relationships: [:files]
			)

		IO.inspect(changeset, label: "Changeset")

    case Ash.create(changeset, domain: GistAsh.Gists, actor: socket.assigns.current_user) do
      {:ok, gist} ->
        {:noreply,
          socket
          |> put_flash(:info, "Gist created successfully")
          |> push_navigate(to: ~p"/gists/#{gist}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
	end

	defp assign_form(socket, _changeset) do
		form =
			AshPhoenix.Form.for_create(
				GistAsh.Gists.Gist,
				:create,
				api: GistAsh.Gists,
				actor: socket.assigns.current_user,
				relationships: [:files]
			)
			|> to_form()

		assign(socket, :form, form)
	end
end
