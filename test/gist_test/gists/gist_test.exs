defmodule GistAsh.Gists.GistTest do
  use GistAsh.DataCase

  # Setup the creator user and reader user
  setup do
    # Create test user
    creator = GistAsh.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test#{System.unique_integer()}@example.com",
        password: "Password123!",
        password_confirmation: "Password123!"
      })
      |> Ash.create!(authorize?: false)

    reader = GistAsh.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test#{System.unique_integer()}@example.com",
        password: "Password123!",
        password_confirmation: "Password123!"
      })
      |> Ash.create!(authorize?: false)

    assert creator.email
    assert reader.email

    {:ok, %{creator: creator, reader: reader}}
  end

  test "ensure only creator can see his private gist", %{creator: creator, reader: reader} do
    gist = GistAsh.Gists.Gist
      |> Ash.Changeset.for_create(:create, %{
        description: "Test Gist",
        public: false,
        files: [%{filename: "test.exs", content: "IO.puts :hello"}],
        user_id: creator.id
      })
      |> Ash.create!(authorize?: false)

    listed_gists_by_creator = GistAsh.Gists.Gist
      |> Ash.Query.load(:files)
      |> Ash.read!(actor: creator)

    listed_gists_by_reader = GistAsh.Gists.Gist
      |> Ash.Query.load(:files)
      |> Ash.read!(actor: reader)

    assert Enum.any?(listed_gists_by_creator, &(&1.id == gist.id))
    assert Enum.empty?(listed_gists_by_reader)
  end

  test "ensure everyone can see a public gist", %{creator: creator, reader: reader} do
    gist = GistAsh.Gists.Gist
      |> Ash.Changeset.for_create(:create, %{
        description: "Test Gist",
        public: true,
        files: [%{filename: "test.exs", content: "IO.puts :hello"}],
        user_id: creator.id
      })
      |> Ash.create!(authorize?: false)

    listed_gists_by_creator = GistAsh.Gists.Gist
      |> Ash.Query.load(:files)
      |> Ash.read!(actor: creator)

    listed_gists_by_reader = GistAsh.Gists.Gist
      |> Ash.Query.load(:files)
      |> Ash.read!(actor: reader)

    assert Enum.any?(listed_gists_by_creator, &(&1.id == gist.id))
    assert Enum.any?(listed_gists_by_reader, &(&1.id == gist.id))
  end
end
