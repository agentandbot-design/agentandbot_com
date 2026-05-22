defmodule GovernanceCore.Personas.Persona do
  @moduledoc """
  Schema for the Identity Passport (Humans and Bots).
  Supports the 'Plug-and-Play' swarm architecture with hardware specs,
  karma (trust_score), and channel-specific metadata.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "personas" do
    field(:name, :string)
    field(:role, :string)
    # picolaw, agentzero, human_admin, etc.
    field(:type, :string, default: "picoclaw")

    # IDENTITY PASSPORT & SWARM FIELDS
    # bot, human
    field(:sub_type, :string, default: "bot")
    # internal (Harezm), external (Marketplace)
    field(:access_group, :string, default: "external")
    # x402 protocol precision
    field(:balance_cents, :integer, default: 0)
    # Hardware specs (gpu, ram), channel IDs (telegram_id)
    field(:metadata, :map, default: %{})

    field(:skills, {:array, :string}, default: [])
    field(:category, :string)
    field(:description, :string)
    field(:protocol, :string, default: "ABL.ONE/1.0")
    field(:runtime_kind, :string, default: "custom")
    field(:runtime_provider, :string, default: "external")
    field(:hosting_mode, :string, default: "affiliate")
    field(:hosting_url, :string)
    field(:agent_card_url, :string)
    field(:interop_standards, {:array, :string}, default: [])

    field(:trust_score, :integer, default: 100)
    # active, paused, safety_shutdown, error
    field(:status, :string, default: "active")

    field(:daily_token_limit, :integer, default: 100_000)
    field(:tokens_used_today, :integer, default: 0)
    field(:memory_limit_mb, :integer, default: 128)
    field(:cpu_limit, :float, default: 0.5)

    field(:price_monthly, :integer, default: 0)
    field(:owner, :string, default: "anonymous")

    # OPERATIONAL STATS
    field(:uptime, :string, default: "100%")
    field(:tasks_done, :integer, default: 0)
    field(:last_seen, :naive_datetime)
    field(:logs, {:array, :string}, default: [])

    # CAREER AND PORTABILITY STATS
    field(:level, :integer, default: 1)
    field(:xp, :integer, default: 0)
    field(:achievements, {:array, :string}, default: [])
    field(:memory_keys_count, :integer, default: 0)
    field(:deployed_endpoint, :string)

    timestamps()
  end

  @doc false
  def changeset(persona, attrs) do
    persona
    |> cast(attrs, [
      :name,
      :role,
      :type,
      :sub_type,
      :access_group,
      :balance_cents,
      :status,
      :trust_score,
      :description,
      :category,
      :skills,
      :metadata,
      :protocol,
      :runtime_kind,
      :runtime_provider,
      :hosting_mode,
      :hosting_url,
      :agent_card_url,
      :interop_standards,
      :price_monthly,
      :owner,
      :level,
      :xp,
      :achievements,
      :memory_keys_count,
      :deployed_endpoint,
      :tasks_done
    ])
    |> validate_required([:name, :sub_type, :access_group, :status])
    |> validate_inclusion(:sub_type, ["bot", "human"])
    |> validate_inclusion(:access_group, ["internal", "external"])
    |> validate_inclusion(:runtime_kind, [
      "hermes",
      "agent_zero",
      "openclaw",
      "google_agent",
      "manus_style",
      "space_agent",
      "minimax_agent",
      "custom_webhook",
      "custom"
    ])
    |> validate_inclusion(:hosting_mode, ["affiliate", "external", "managed"])
    |> validate_number(:trust_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
