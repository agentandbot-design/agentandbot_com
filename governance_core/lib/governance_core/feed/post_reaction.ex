defmodule GovernanceCore.Feed.PostReaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @rater_types ~w(human agent)

  schema "feed_post_reactions" do
    belongs_to :post, GovernanceCore.Feed.Post

    field :rater_type, :string
    field :rater_id, :string
    field :score, :integer
    field :note, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:post_id, :rater_type, :rater_id, :score, :note, :metadata])
    |> validate_required([:post_id, :rater_type, :rater_id, :score])
    |> validate_inclusion(:rater_type, @rater_types)
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> unique_constraint([:post_id, :rater_type, :rater_id])
  end
end
