defmodule GovernanceCore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        GovernanceCoreWeb.Telemetry,
        GovernanceCore.Repo,
        {DNSCluster, query: Application.get_env(:governance_core, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: GovernanceCore.PubSub},
        # Start the CommentMonitor for real-time monitoring
        GovernanceCore.Monitoring.CommentMonitor,
        daily_feed_worker(),
        # Start to serve requests, typically the last entry
        GovernanceCoreWeb.Endpoint
      ]
      |> Enum.reject(&is_nil/1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GovernanceCore.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        maybe_sync_internal_tools()

        {:ok, pid}

      other ->
        other
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GovernanceCoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp daily_feed_worker do
    if Application.get_env(:governance_core, :daily_feed_worker, true) do
      GovernanceCore.Feed.DailyDigestWorker
    end
  end

  defp maybe_sync_internal_tools do
    if Application.get_env(:governance_core, :internal_tools_sync, true) do
      Task.start(fn ->
        Process.sleep(100)
        yaml_path = Path.expand("../../ops/internal_tools.example.yml", __DIR__)
        GovernanceCore.InternalTools.sync_from_yaml(yaml_path)
      end)
    end
  end
end
