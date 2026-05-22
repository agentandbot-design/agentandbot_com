defmodule GovernanceCore.Agents do
  @moduledoc """
  Unified context for Agents (Humans and Bots).
  Single source of truth for the 'Plug-and-Play' Swarm Architecture.
  """

  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo
  import Ecto.Query

  @doc "Returns all agents."
  def list_agents do
    Repo.all(Persona)
  end

  @doc "Returns internal (Harezm) agents."
  def list_internal do
    Persona
    |> where([p], p.access_group == "internal")
    |> Repo.all()
  end

  @doc "Returns external (Marketplace) agents."
  def list_external do
    Persona
    |> where([p], p.access_group == "external")
    |> Repo.all()
  end

  @doc "Returns a single agent by ID."
  def get_agent(id) do
    Repo.get(Persona, id)
  end

  def get_agent!(id) do
    Repo.get!(Persona, id)
  end

  @doc "Search agents by name or role."
  def search(query) when query in ["", nil], do: list_agents()

  def search(query) do
    q = "%#{String.downcase(query)}%"

    Persona
    |> where(
      [p],
      fragment("lower(coalesce(?, '')) LIKE ?", p.name, ^q) or
        fragment("lower(coalesce(?, '')) LIKE ?", p.role, ^q) or
        fragment("lower(coalesce(?, '')) LIKE ?", p.description, ^q)
    )
    |> Repo.all()
  end

  @doc "Dashboard summary stats for the Swarm OS."
  def swarm_stats do
    agents = Repo.all(Persona)

    %{
      total: length(agents),
      humans: Enum.count(agents, &(&1.sub_type == "human")),
      bots: Enum.count(agents, &(&1.sub_type == "bot")),
      active: Enum.count(agents, &(&1.status == "active")),
      active_scenarios: 0,
      spend_cents: Repo.one(from p in Persona, select: sum(p.balance_cents)) || 0
    }
  end

  @doc "Creates an agent."
  def create_agent(attrs \\ %{}) do
    %Persona{}
    |> Persona.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates an agent."
  def update_agent(%Persona{} = agent, attrs) do
    agent
    |> Persona.changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes an agent."
  def delete_agent(%Persona{} = agent) do
    Repo.delete(agent)
  end

  @doc "Charge an agent (AP2/x402 protocol)."
  def charge_agent(%Persona{} = agent, amount_cents) do
    # Implementation of x402 charge logic
    new_balance = agent.balance_cents + amount_cents
    update_agent(agent, %{balance_cents: new_balance})
  end

  @doc """
  Determine the best available channel (Hierarchy/Fallback).
  Baseline (0s): Markdown (Always active)
  Upgraded: Telegram, Email, Windmill
  """
  def get_best_channel(%Persona{} = agent) do
    # Fallback Hierarchy: High-Fidelity -> Baseline
    cond do
      Map.get(agent.metadata, "windmill_wf") -> :windmill
      Map.get(agent.metadata, "telegram_id") -> :telegram
      Map.get(agent.metadata, "email") -> :email
      # 30-second Identity Baseline
      true -> :markdown
    end
  end
end
