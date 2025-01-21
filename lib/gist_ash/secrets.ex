defmodule GistAsh.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], GistAsh.Accounts.User, _opts) do
    Application.fetch_env(:gist_ash, :token_signing_secret)
  end
end
