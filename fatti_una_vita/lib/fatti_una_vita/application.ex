defmodule FattiUnaVita.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FattiUnaVitaWeb.Telemetry,
      FattiUnaVita.Repo,
      {DNSCluster, query: Application.get_env(:fatti_una_vita, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FattiUnaVita.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: FattiUnaVita.Finch},
      # Start a worker by calling: FattiUnaVita.Worker.start_link(arg)
      # {FattiUnaVita.Worker, arg},
      # Start to serve requests, typically the last entry
      FattiUnaVitaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FattiUnaVita.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FattiUnaVitaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
