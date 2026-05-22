defmodule GovernanceCoreWeb.Api.TaskController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Marketplace

  def create(conn, params) do
    case Marketplace.create_task(params) do
      {:ok, task} ->
        conn
        |> put_status(:accepted)
        |> json(%{data: task_payload(task), message: "Task escrowed and queued"})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def show(conn, %{"id" => id}) do
    case Marketplace.get_task(id) do
      nil ->
        error_response(conn, :not_found)

      task ->
        json(conn, %{data: task_payload(task)})
    end
  end

  def event(conn, %{"id" => id, "event_type" => event_type} = params) do
    case Marketplace.record_event(id, event_type, params) do
      {:ok, task} -> json(conn, %{data: task_payload(task), message: "Task event recorded"})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  def artifact(conn, %{"id" => id} = params) do
    case Marketplace.submit_artifact(id, params) do
      {:ok, task} -> json(conn, %{data: task_payload(task), message: "Artifact submitted"})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  def delegate(conn, %{"id" => id} = params) do
    case Marketplace.delegate_task(id, params) do
      {:ok, task} ->
        conn
        |> put_status(:accepted)
        |> json(%{data: task_payload(task), message: "Task delegated"})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def message(conn, %{"id" => id} = params) do
    case Marketplace.send_task_message(id, params) do
      {:ok, task} -> json(conn, %{data: task_payload(task), message: "Task message recorded"})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  def commerce_intent(conn, %{"id" => id} = params) do
    case Marketplace.create_commerce_intent(id, params) do
      {:ok, task} -> json(conn, %{data: task_payload(task), message: "Commerce intent recorded"})
      {:error, reason} -> error_response(conn, reason)
    end
  end

  def callback(conn, %{"id" => id, "status" => "working"} = params) do
    message = params["message"] || "Ajan otonom olarak çalışmaya devam ediyor..."
    metadata = Map.get(params, "metadata", %{})

    case Marketplace.record_event(id, "working", %{"message" => message, "metadata" => metadata}) do
      {:ok, task} ->
        Phoenix.PubSub.broadcast(
          GovernanceCore.PubSub,
          "scenario_board",
          {:task_updated, task}
        )

        json(conn, %{data: task_payload(task), message: "Task callback working status accepted"})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def callback(conn, %{"id" => id, "status" => "completed"} = params) do
    artifact_url = params["artifact_url"] || "/artifacts/task-#{id}-output.md"

    result_summary =
      params["result_summary"] || params["message"] ||
        "Görev çıktısı başarıyla sisteme aktarıldı."

    portfolio_attrs = %{
      "artifact_url" => artifact_url,
      "message" => result_summary,
      "metadata" => %{
        "portfolio" => %{
          "public" => Map.get(params, "portfolio_public", true),
          "summary" => Map.get(params, "portfolio_summary", result_summary),
          "artifact_type" => Map.get(params, "artifact_type", "report")
        },
        "output" => Map.get(params, "output", result_summary)
      }
    }

    case Marketplace.submit_artifact(id, portfolio_attrs) do
      {:ok, task} ->
        Phoenix.PubSub.broadcast(
          GovernanceCore.PubSub,
          "scenario_board",
          {:task_updated, task}
        )

        json(conn, %{
          data: task_payload(task),
          message: "Task callback completed, artifact submitted to escrow"
        })

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def callback(conn, %{"id" => id, "status" => "failed"} = params) do
    error_message = params["message"] || params["error"] || "Unknown task execution error."
    metadata = Map.get(params, "metadata", %{})

    case Marketplace.record_event(id, "failed", %{
           "message" => error_message,
           "metadata" => metadata
         }) do
      {:ok, task} ->
        Phoenix.PubSub.broadcast(
          GovernanceCore.PubSub,
          "scenario_board",
          {:task_updated, task}
        )

        json(conn, %{
          data: task_payload(task),
          message: "Task callback failure handled, refund processed"
        })

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  def callback(conn, %{"id" => id} = params) do
    status = params["status"] || "working"
    message = params["message"] || "Görev durum güncellemesi: #{status}"
    metadata = Map.get(params, "metadata", %{})

    case Marketplace.record_event(id, status, %{"message" => message, "metadata" => metadata}) do
      {:ok, task} ->
        Phoenix.PubSub.broadcast(
          GovernanceCore.PubSub,
          "scenario_board",
          {:task_updated, task}
        )

        json(conn, %{data: task_payload(task), message: "Task callback state update accepted"})

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  defp task_payload(task) do
    %{
      id: task.id,
      agent_id: task.agent_id,
      created_by: task.created_by,
      title: task.title,
      instructions: task.instructions,
      required_skill: task.required_skill,
      expected_artifact: task.expected_artifact,
      deadline_at: task.deadline_at,
      budget_credits: task.budget_credits,
      status: task.status,
      artifact_url: task.artifact_url,
      portfolio: get_in(task.metadata || %{}, ["portfolio"]),
      delegated_from_task_id: task.delegated_from_task_id,
      events:
        Enum.map(task.events || [], fn event ->
          %{
            id: event.id,
            event_type: event.event_type,
            actor: event.actor,
            message: event.message,
            artifact_url: event.artifact_url,
            metadata: event.metadata,
            inserted_at: event.inserted_at
          }
        end)
    }
  end

  defp error_response(conn, :not_found) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Task not found"})
  end

  defp error_response(conn, :agent_not_found) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Agent not found"})
  end

  defp error_response(conn, :insufficient_credits) do
    conn
    |> put_status(:payment_required)
    |> json(%{
      error: "Insufficient internal credits",
      payment: %{type: "internal_credits", next_step: "Top up credits before creating this task"}
    })
  end

  defp error_response(conn, :budget_exceeds_policy) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "Task budget exceeds agent owner policy"})
  end

  defp error_response(conn, :skill_not_allowed) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "Required skill is not allowed by agent owner policy"})
  end

  defp error_response(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Validation failed", details: inspect(changeset.errors)})
  end

  defp error_response(conn, reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Task operation failed", reason: inspect(reason)})
  end
end
