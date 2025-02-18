import Config
config :gist_ash, token_signing_secret: "UDuBXhHC14sDrTJ+YtJyPl4sOkjwKgIx"
config :ash, disable_async?: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gist_ash, GistAsh.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "gist_ash_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gist_ash, GistAshWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XHYhB5zydeArPz8WtssUB+t9kUdKvMbKCgF+ZWI8Y0D6/H/F0oDATsWKuykR7qwO",
  server: false

# In test we don't send emails
config :gist_ash, GistAsh.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
