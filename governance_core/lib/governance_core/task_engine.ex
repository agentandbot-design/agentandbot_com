defmodule GovernanceCore.TaskEngine do
  @moduledoc """
  Manages task delegation based on agent trust scores (Karma).
  Implements the "Hybrid Task Engine" logic where low-trust agents are handed off to humans.
  """
  alias GovernanceCore.Agents
  require Logger

  @human_handoff_threshold 50

  def delegate_task(agent_id, _task_payload) do
    agent = Agents.get_agent!(agent_id)

    if agent.trust_score < @human_handoff_threshold do
      Logger.warning(
        "Agent #{agent.id} karma (#{agent.trust_score}) below threshold. Falling back to Human/Manual Handoff."
      )

      {:error, :human_handoff}
    else
      channel = Agents.get_best_channel(agent)
      Logger.info("Delegating task to agent #{agent.id} via channel: #{channel}")
      {:ok, channel}
    end
  end

  def verify_result(agent_id, is_valid) do
    agent = Agents.get_agent!(agent_id)

    new_score =
      if is_valid do
        min(agent.trust_score + 1, 100)
      else
        max(agent.trust_score - 10, 0)
      end

    case Agents.update_agent(agent, %{trust_score: new_score}) do
      {:ok, updated_agent} ->
        if updated_agent.trust_score < @human_handoff_threshold do
          Logger.alert(
            "Agent #{agent.id} trust score dropped below critical level! Monitoring required."
          )
        end

        {:ok, updated_agent}

      error ->
        error
    end
  end
end
