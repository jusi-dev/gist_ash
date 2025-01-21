defmodule GistAsh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GistAshWeb.Telemetry,
      GistAsh.Repo,
      {DNSCluster, query: Application.get_env(:gist_ash, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GistAsh.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GistAsh.Finch},
      # Start a worker by calling: GistAsh.Worker.start_link(arg)
      # {GistAsh.Worker, arg},
      # Start to serve requests, typically the last entry
      GistAshWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :gist_ash]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GistAsh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GistAshWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
