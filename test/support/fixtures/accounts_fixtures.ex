defmodule GistAsh.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GistAsh.Accounts` context.
  """

  alias GistAsh.Accounts
  alias GistAsh.Accounts.User

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{
      email: unique_user_email(),
      password: "testpassword",
      password_confirmation: "testpassword"
    })

    {:ok, user} =
      GistAsh.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, attrs)
      |> GistAsh.Accounts.create!()

    user
  end

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a user registration: valid attributes.
  """
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: "testpassword",
      password_confirmation: "testpassword"
    })
  end

  @doc """
  Setup helper that registers and logs in users.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Log in the given user in the connection.
  """
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end
end
