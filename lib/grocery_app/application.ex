defmodule GroceryApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GroceryAppWeb.Telemetry,
      GroceryApp.Repo,
      {DNSCluster, query: Application.get_env(:grocery_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GroceryApp.PubSub},
      {PlaywrightEx.Supervisor,
       [
         executable: Path.join([File.cwd!(), "assets/node_modules/.bin/playwright"]),
         timeout: 30_000
       ]},
      GroceryAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GroceryApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GroceryAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
