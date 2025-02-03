# test/gist_ash_web/live/gist_live/new_test.exs
defmodule GistAshWeb.GistLive.NewTest do
  use GistAshWeb.ConnCase
  import Phoenix.LiveViewTest
  import AshAuthentication.Jwt

  require Ash.Query

  setup %{conn: conn} do
    # Create test user
    user = create_test_user()

    subject = AshAuthentication.user_to_subject(user)

    # Create authenticated connection
    authed_conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session("user", subject)

    {:ok, authed_conn: authed_conn, user: user}
  end

  test "authenticated user can create gist", %{authed_conn: conn, user: user} do
    {:ok, view, html} = live(conn, ~p"/gists/new")

    # Verify initial state
    assert html =~ "Create a new Gist"
    assert has_element?(view, "#gist-form")

    # Build valid params
    file_content = "IO.puts :hello"
    params = %{
      "form" => %{
        "description" => "Test Gist",
        "public" => "true",
        "files" => %{
          "0" => %{
            "filename" => "test.exs",
            "content" => file_content
          }
        }
      }
    }

    # Submit form
    view
    |> form("#gist-form", params)
    |> render_submit()

    submitted_gist =
      GistAsh.Gists.Gist
      |> Ash.Query.filter(description == "Test Gist")
      |> Ash.read_first!()


    IO.inspect(submitted_gist, label: "view")

    # Verify response
    assert_redirected(view, ~p"/gists/#{submitted_gist.id}")

    # Verify database state
    gist =
      GistAsh.Gists.Gist
      |> Ash.Query.filter(user_id == user.id)
      |> Ash.read_first!()

    assert gist.description == "Test Gist"
    assert gist.public == true

    # Verify files
    files = Ash.load!(gist, :files)
    IO.inspect(files, label: "files")
    assert length(files.files) == 1
    # assert files |> List.first() |> Map.get(:filename) == "test.exs"
    # assert files |> List.first() |> Map.get(:content) == file_content
  end

  defp create_test_user do
    GistAsh.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test#{System.unique_integer()}@example.com",
        password: "Password123!",
        password_confirmation: "Password123!"
      })
      |> Ash.create!(
        domain: GistAsh.Accounts,
        authorize?: false # Bypass authorization for test setup
      )
  end
end
