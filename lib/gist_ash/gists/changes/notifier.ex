defmodule GistAsh.Gists.Changes.Notifier do
  @moduledoc """
  Custom change that sends changeset data to an external endpoint
  """

  use Ash.Resource.Change
  require Logger

  alias Ash.Changeset
  alias HTTPoison

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def change(changeset, _opts, _context) do
    endpoint = "https://www.postb.in/1737707669414-3277076042722"

    # Return the result instead of the changeset
    Changeset.after_action(changeset, fn _changeset, result ->
      Logger.info("Sending notification for new gist")
      send_notification(result, endpoint)
      {:ok, result}  # Return the created Gist resource
    end)
  end

  defp send_notification(result, endpoint) do
    payload = %{
      description: result.description,
      public: result.public,
      user_id: result.user_id
    }

    HTTPoison.post(endpoint, Jason.encode!(payload), [{"Content-Type", "application/json"}])
  end
end
