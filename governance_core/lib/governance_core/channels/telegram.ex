defmodule GovernanceCore.Channels.Telegram do
  @behaviour GovernanceCore.Channels.Channel
  require Logger

  @impl true
  def deliver(agent_id, _payload) do
    # In a real swarm, this would call the Telegram API
    Logger.info("Telegram: Delivering message to Agent #{agent_id} via Telegram Bot API")
    :ok
  end

  @impl true
  # MOCKED: Always online
  def status(), do: :online
end
