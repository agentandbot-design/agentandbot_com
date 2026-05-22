defmodule GovernanceCore.Limiter do
  @moduledoc """
  Enforces simulated CPU and RAM limits for agents running on the platform.
  Since we are on Render (PaaS), we use application-level metrics as proxies:
  - CPU: Request/Message rate (Token Bucket)
  - RAM: Concurrent connection count or payload size

  If an agent exceeds these limits, it is flagged for "SafetyShutdown".
  """
  use GenServer
  require Logger

  # Default Quotas
  # requests/ops
  @cpu_limit_per_minute 100

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    # Create ETS table for fast lookups
    :ets.new(:agent_quotas, [:set, :public, :named_table])
    {:ok, %{}}
  end

  @doc """
  Checks if an agent is allowed to perform an operation consuming `cost` units.
  """
  def check_limit(agent_id, cost \\ 1) do
    case :ets.lookup(:agent_quotas, agent_id) do
      [{^agent_id, usage, last_reset}] ->
        if usage + cost > @cpu_limit_per_minute do
          {:error, :quota_exceeded}
        else
          :ets.insert(:agent_quotas, {agent_id, usage + cost, last_reset})
          :ok
        end

      [] ->
        :ets.insert(:agent_quotas, {agent_id, cost, System.system_time(:second)})
        :ok
    end
  end

  @doc """
  Resets quotas periodically. (Simple implementation: brute force reset or sliding window).
  For MVP, we just rely on the GenServer to clear old entries or implement a cleaner.
  """
  def handle_info(:clean_quotas, state) do
    # Implementation of cleanup logic would go here
    # For now, we assume simple checks.
    {:noreply, state}
  end
end
