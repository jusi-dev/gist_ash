defmodule GistAsh.Gists do
  use Ash.Domain

  resources do
      resource GistAsh.Gists.Gist
      resource GistAsh.Gists.File
  end

  def read!(query \\ GistAsh.Gists.Gist) do
    query
    |> Ash.Query.for_read(:read)
    |> Ash.read!(domain: __MODULE__)
  end

end
