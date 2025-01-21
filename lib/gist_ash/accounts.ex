defmodule GistAsh.Accounts do
  use Ash.Domain, otp_app: :gist_ash, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource GistAsh.Accounts.Token
    resource GistAsh.Accounts.User
  end
end
