defmodule GovernanceCore.Payment.Credits do
  @moduledoc """
  Handles atomized credit operations for subscriptions.
  """
  alias Ecto.Multi
  alias GovernanceCore.Repo
  alias GovernanceCore.Payment.Subscription

  def deduct_credit(subscription_id) do
    Multi.new()
    |> Multi.run(:subscription, fn _repo, _changes ->
      case Repo.get(Subscription, subscription_id) do
        nil -> {:error, :not_found}
        sub -> {:ok, sub}
      end
    end)
    |> Multi.run(:update, fn _repo, %{subscription: sub} ->
      if sub.credits_remaining > 0 do
        sub
        |> Subscription.changeset(%{credits_remaining: sub.credits_remaining - 1})
        |> Repo.update()
      else
        {:error, :insufficient_credits}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update: updated_sub}} -> {:ok, updated_sub.credits_remaining}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  def add_credits(subscription_id, amount) do
    Multi.new()
    |> Multi.run(:subscription, fn _repo, _changes ->
      case Repo.get(Subscription, subscription_id) do
        nil -> {:error, :not_found}
        sub -> {:ok, sub}
      end
    end)
    |> Multi.run(:update, fn _repo, %{subscription: sub} ->
      sub
      |> Subscription.changeset(%{credits_remaining: sub.credits_remaining + amount})
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update: updated_sub}} -> {:ok, updated_sub.credits_remaining}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end
end
