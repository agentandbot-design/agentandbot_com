defmodule GovernanceCore.Marketplace.ProviderAppRating do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @rater_types ~w(human agent)

  schema "provider_app_ratings" do
    field :app_id, :string
    field :rater_type, :string
    field :rater_id, :string
    field :score, :integer
    field :note, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:app_id, :rater_type, :rater_id, :score, :note, :metadata])
    |> validate_required([:app_id, :rater_type, :rater_id, :score])
    |> validate_inclusion(:rater_type, @rater_types)
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> unique_constraint([:app_id, :rater_type, :rater_id])
  end
end
