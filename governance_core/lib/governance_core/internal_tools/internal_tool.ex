defmodule GovernanceCore.InternalTools.InternalTool do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(active degraded maintenance planned disabled unknown)
  @agent_access_modes ~w(false true read_only scoped_service_accounts_only)
  @data_classes ~w(public internal confidential restricted)

  schema "internal_tools" do
    field :slug, :string
    field :name, :string
    field :url, :string
    field :internal_url, :string
    field :container_name, :string
    field :category, :string
    field :owner, :string
    field :audience, {:array, :string}, default: []
    field :agent_access, :string, default: "false"
    field :status, :string, default: "unknown"
    field :auth_mode, :string
    field :health, :string, default: "unknown"
    field :data_classification, :string, default: "internal"
    field :allowed_agent_scopes, {:array, :string}, default: []
    field :secrets_ref, :string
    field :notes, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [
      :slug,
      :name,
      :url,
      :internal_url,
      :container_name,
      :category,
      :owner,
      :audience,
      :agent_access,
      :status,
      :auth_mode,
      :health,
      :data_classification,
      :allowed_agent_scopes,
      :secrets_ref,
      :notes,
      :metadata
    ])
    |> validate_required([:slug, :name, :category])
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9\-]*$/)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:agent_access, @agent_access_modes)
    |> validate_inclusion(:data_classification, @data_classes)
    |> validate_no_secret_values()
    |> unique_constraint(:slug)
  end

  defp validate_no_secret_values(changeset) do
    fields = [:url, :internal_url, :secrets_ref, :notes]

    Enum.reduce(fields, changeset, fn field, acc ->
      value = get_field(acc, field)

      if secret_like?(value) do
        add_error(acc, field, "must not contain raw credentials or tokens")
      else
        acc
      end
    end)
  end

  defp secret_like?(value) when is_binary(value) do
    Regex.match?(~r/(password|passwd|token=|api[_-]?key|secret=|invite\/[a-z0-9]{12,})/i, value)
  end

  defp secret_like?(_value), do: false
end
