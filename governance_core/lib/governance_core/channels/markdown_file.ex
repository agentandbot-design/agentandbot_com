defmodule GovernanceCore.Channels.MarkdownFile do
  @behaviour GovernanceCore.Channels.Channel
  require Logger

  @impl true
  def deliver(agent_id, payload) do
    # Baseline: Writing task to a shared workspace or node-specific folder
    # In a real swarm, this would sync to the agent's local filesystem.
    filename = "tasks/task_#{agent_id}_#{DateTime.utc_now() |> DateTime.to_unix()}.md"

    _content = """
    # Task Assignment (Markdown Fallback)
    - **Agent ID**: #{agent_id}
    - **Priority**: #{Map.get(payload, :priority, "normal")}
    - **Action**: #{Map.get(payload, :action, "No action specified")}
    """

    Logger.info("Markdown Baseline: Writing task file to #{filename}")
    # In-memory mock for now, or actual file write if needed.
    :ok
  end

  @impl true
  # Markdown baseline is always online
  def status(), do: :online
end
