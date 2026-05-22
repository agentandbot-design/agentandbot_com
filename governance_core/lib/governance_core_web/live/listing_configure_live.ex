defmodule GovernanceCoreWeb.ListingConfigureLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Marketplace

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    listing = Marketplace.get_listing(id)
    action = Map.get(params, "action", "configure")

    {:ok,
     assign(socket,
       listing: listing,
       action: action,
       title: if(listing, do: "Task for #{listing.title}", else: ""),
       instructions: "",
       expected_artifact: "",
       required_skill: first_skill(listing),
       budget_credits: if(listing, do: to_string(listing.task_price_credits), else: "0"),
       configuration: default_configuration(listing),
       page_title: if(listing, do: "Configure #{listing.title}", else: "Listing Not Found"),
       current_path: "/listings/#{id}/configure"
     )}
  end

  @impl true
  def handle_event("set", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign_field(socket, field, value)}
  end

  @impl true
  def handle_event("configure", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, configuration: Map.put(socket.assigns.configuration, field, value))}
  end

  @impl true
  def handle_event("hire", _params, socket) do
    listing = socket.assigns.listing

    params = %{
      "created_by" => "local_user",
      "title" => socket.assigns.title,
      "instructions" => socket.assigns.instructions,
      "expected_artifact" => socket.assigns.expected_artifact,
      "required_skill" => socket.assigns.required_skill,
      "budget_credits" => socket.assigns.budget_credits,
      "configuration" => socket.assigns.configuration
    }

    case Marketplace.hire_listing(listing.id, params) do
      {:ok, _task} ->
        {:noreply, socket |> put_flash(:info, "Task escrowed.") |> push_navigate(to: "/agents")}

      {:error, :insufficient_credits} ->
        {:noreply, put_flash(socket, :error, "Not enough credits.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Hire failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("rent", _params, socket) do
    case Marketplace.rent_listing(socket.assigns.listing.id, %{
           "created_by" => "local_user",
           "configuration" => socket.assigns.configuration
         }) do
      {:ok, _contract} ->
        {:noreply, socket |> put_flash(:info, "Rental active.") |> push_navigate(to: "/agents")}

      {:error, :insufficient_credits} ->
        {:noreply, put_flash(socket, :error, "Not enough credits.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Rental failed: #{inspect(reason)}")}
    end
  end

  defp assign_field(socket, "title", value), do: assign(socket, title: value)
  defp assign_field(socket, "instructions", value), do: assign(socket, instructions: value)

  defp assign_field(socket, "expected_artifact", value),
    do: assign(socket, expected_artifact: value)

  defp assign_field(socket, "required_skill", value), do: assign(socket, required_skill: value)
  defp assign_field(socket, "budget_credits", value), do: assign(socket, budget_credits: value)
  defp assign_field(socket, _field, _value), do: socket

  defp first_skill(nil), do: ""
  defp first_skill(%{required_skills: [skill | _]}), do: skill
  defp first_skill(_listing), do: ""

  defp default_configuration(nil), do: %{}
  defp default_configuration(%{default_configuration: config}) when is_map(config), do: config
  defp default_configuration(_listing), do: %{}

  defp schema_fields(nil), do: []

  defp schema_fields(%{configuration_schema: %{"fields" => fields}}) when is_list(fields),
    do: fields

  defp schema_fields(_listing), do: []

  defp supports?(%{fulfillment_mode: mode}, action), do: mode == action or mode == "both"
  defp supports?(_, _), do: false

  defp profile(%{metadata: %{"kadro_profile" => profile}}) when is_map(profile), do: profile
  defp profile(_listing), do: %{}

  defp profile_value(listing, key), do: Map.get(profile(listing), key)

  defp initials(title) do
    title
    |> to_string()
    |> String.split(" ", trim: true)
    |> Enum.map_join("", &String.first/1)
    |> String.slice(0, 2)
    |> String.upcase()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="listing-flow">
      <%= if @listing do %>
        <header class="flow-header">
          <p class="market-kicker">Configure</p>
          <h1>{@listing.title}</h1>
          <p>{@listing.summary}</p>
        </header>

        <section class="flow-card">
          <div class="flow-card-body">
            <div class="configure-worker-strip">
              <div class="worker-avatar">
                <%= if profile_value(@listing, "headshot_url") do %>
                  <img
                    src={profile_value(@listing, "headshot_url")}
                    alt={"#{@listing.title} headshot"}
                  />
                <% else %>
                  <span>{initials(@listing.title)}</span>
                <% end %>
              </div>
              <div>
                <span>AI worker persona</span>
                <strong>{profile_value(@listing, "profession") || @listing.summary}</strong>
                <p>{profile_value(@listing, "personality") || @listing.summary}</p>
              </div>
            </div>

            <div class="agent-meta-grid is-wide">
              <div>
                <span>Runtime</span>
                <b>{@listing.runtime_kind}</b>
              </div>
              <div>
                <span>Hosting</span>
                <b>{@listing.hosting_mode}</b>
              </div>
              <div>
                <span>Task</span>
                <b>{@listing.task_price_credits} credits</b>
              </div>
              <div>
                <span>Rent</span>
                <b>{@listing.rental_price_credits}/{@listing.rental_period}</b>
              </div>
            </div>

            <div class="field-stack">
              <%= for field <- schema_fields(@listing) do %>
                <label>
                  <span>{field["label"] || field["name"]}</span>
                  <input
                    class="market-input"
                    value={Map.get(@configuration, field["name"], "")}
                    phx-keyup="configure"
                    phx-value-field={field["name"]}
                    phx-debounce="300"
                  />
                </label>
              <% end %>
            </div>

            <div class="soft-divider"></div>

            <input
              class="market-input"
              value={@title}
              phx-keyup="set"
              phx-value-field="title"
              phx-debounce="300"
            />
            <textarea
              class="market-textarea"
              placeholder="Task instructions"
              phx-keyup="set"
              phx-value-field="instructions"
              phx-debounce="300"
            ><%= @instructions %></textarea>
            <div class="field-grid">
              <input
                class="market-input"
                value={@required_skill}
                phx-keyup="set"
                phx-value-field="required_skill"
                phx-debounce="300"
              />
              <input
                class="market-input"
                value={@expected_artifact}
                placeholder="Expected artifact"
                phx-keyup="set"
                phx-value-field="expected_artifact"
                phx-debounce="300"
              />
              <input
                class="market-input"
                type="number"
                min="0"
                value={@budget_credits}
                phx-keyup="set"
                phx-value-field="budget_credits"
                phx-debounce="300"
              />
            </div>

            <div class="flow-actions is-end">
              <a href="/agents" class="action-muted">Back</a>
              <%= if @listing.provider_url || @listing.external_setup_url do %>
                <a
                  href={@listing.provider_url || @listing.external_setup_url}
                  target="_blank"
                  rel="noopener"
                  class="action-muted"
                >
                  Use provider
                </a>
              <% end %>
              <button class="action-muted" phx-click="rent" disabled={!supports?(@listing, "rental")}>
                Rent monthly
              </button>
              <button
                class="market-primary-action"
                phx-click="hire"
                disabled={!supports?(@listing, "task_hire")}
              >
                Hire for one task
              </button>
            </div>
          </div>
        </section>
      <% else %>
        <div class="flow-card">
          <div class="flow-card-body">
            <h1>Listing not found</h1>
            <a href="/agents" class="market-primary-action">Back to marketplace</a>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
