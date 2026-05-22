defmodule GovernanceCoreWeb.ListingNewLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Marketplace
  alias GovernanceCore.RuntimeCatalog

  @impl true
  def mount(params, _session, socket) do
    listing = params["id"] && Marketplace.get_listing(params["id"])
    mode = socket.assigns[:live_action] || :new

    {:ok,
     assign(socket,
       mode: mode,
       listing: listing,
       step: 1,
       title: initial_title(listing, mode),
       summary: listing_value(listing, :summary, ""),
       source_type: listing_value(listing, :source_type, "seller_agent"),
       fulfillment_mode: listing_value(listing, :fulfillment_mode, "both"),
       runtime_kind: listing_value(listing, :runtime_kind, "custom_webhook"),
       hosting_mode: listing_value(listing, :hosting_mode, "self_hosted"),
       provider_url: listing_value(listing, :provider_url, ""),
       external_setup_url: listing_value(listing, :external_setup_url, ""),
       headshot_url: profile_value(listing, "headshot_url") || "",
       full_body_url: profile_value(listing, "full_body_url") || "",
       profession: profile_value(listing, "profession") || listing_value(listing, :summary, ""),
       personality: profile_value(listing, "personality") || listing_value(listing, :summary, ""),
       content: profile_value(listing, "content") || "",
       age: profile_value(listing, "age") || "",
       gender: profile_value(listing, "gender") || "",
       country: profile_value(listing, "country") || "",
       city: profile_value(listing, "city") || "",
       email: profile_value(listing, "email") || "",
       phone: profile_value(listing, "phone") || "",
       telegram: profile_value(listing, "telegram") || "",
       whatsapp: profile_value(listing, "whatsapp") || "",
       height_cm: profile_value(listing, "height_cm") || "",
       weight_kg: profile_value(listing, "weight_kg") || "",
       instagram: profile_value(listing, "instagram") || "",
       tiktok: profile_value(listing, "tiktok") || "",
       linkedin: profile_value(listing, "linkedin") || "",
       youtube: profile_value(listing, "youtube") || "",
       x: profile_value(listing, "x") || "",
       facebook: profile_value(listing, "facebook") || "",
       cv_url: profile_value(listing, "cv_url") || "",
       required_skills:
         csv_value(listing && listing.required_skills, "deliver_artifact, receive_task"),
       standards: csv_value(listing && listing.standards, "MCP, OpenAPI 3.1"),
       configuration_schema: %{
         "fields" => [
           %{"name" => "goal", "label" => "Goal", "type" => "text"},
           %{"name" => "tone", "label" => "Tone", "type" => "text"},
           %{"name" => "delivery", "label" => "Delivery", "type" => "text"}
         ]
       },
       task_price_credits: listing_value(listing, :task_price_credits, "5") |> to_string(),
       rental_price_credits: listing_value(listing, :rental_price_credits, "50") |> to_string(),
       rental_period: listing_value(listing, :rental_period, "monthly"),
       runtimes: RuntimeCatalog.runtimes(),
       page_title: page_title(mode),
       current_path: current_path(listing, mode)
     )}
  end

  @impl true
  def handle_event("next", _params, %{assigns: %{step: step}} = socket) when step < 4 do
    {:noreply, assign(socket, step: step + 1)}
  end

  @impl true
  def handle_event("back", _params, %{assigns: %{step: step}} = socket) when step > 1 do
    {:noreply, assign(socket, step: step - 1)}
  end

  @impl true
  def handle_event("set", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign_field(socket, field, value)}
  end

  @impl true
  def handle_event("select", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign_field(socket, field, value)}
  end

  @impl true
  def handle_event("save", %{"status" => status}, socket) do
    attrs = %{
      seller_id: "local_user",
      title: socket.assigns.title,
      summary: socket.assigns.summary,
      source_type: socket.assigns.source_type,
      fulfillment_mode: socket.assigns.fulfillment_mode,
      runtime_kind: socket.assigns.runtime_kind,
      hosting_mode: socket.assigns.hosting_mode,
      provider_id: if(socket.assigns.provider_url == "", do: nil, else: "custom_partner"),
      provider_url: blank_to_nil(socket.assigns.provider_url),
      external_setup_url: blank_to_nil(socket.assigns.external_setup_url),
      required_skills: socket.assigns.required_skills,
      standards: socket.assigns.standards,
      configuration_schema: socket.assigns.configuration_schema,
      task_price_credits: socket.assigns.task_price_credits,
      rental_price_credits: socket.assigns.rental_price_credits,
      rental_period: socket.assigns.rental_period,
      status: status,
      metadata: %{
        "worker_kind" => "ai_worker_persona",
        "kadro_profile" => %{
          "category" => profile_value(socket.assigns.listing, "category") || "Agent",
          "profession" => blank_to_nil(socket.assigns.profession) || socket.assigns.summary,
          "personality" => blank_to_nil(socket.assigns.personality) || socket.assigns.summary,
          "content" => blank_to_nil(socket.assigns.content) || socket.assigns.required_skills,
          "age" => blank_to_nil(socket.assigns.age),
          "gender" => blank_to_nil(socket.assigns.gender),
          "country" => blank_to_nil(socket.assigns.country),
          "city" => blank_to_nil(socket.assigns.city),
          "email" => blank_to_nil(socket.assigns.email),
          "phone" => blank_to_nil(socket.assigns.phone),
          "telegram" => blank_to_nil(socket.assigns.telegram),
          "whatsapp" => blank_to_nil(socket.assigns.whatsapp),
          "height_cm" => blank_to_nil(socket.assigns.height_cm),
          "weight_kg" => blank_to_nil(socket.assigns.weight_kg),
          "instagram" => blank_to_nil(socket.assigns.instagram),
          "tiktok" => blank_to_nil(socket.assigns.tiktok),
          "linkedin" => blank_to_nil(socket.assigns.linkedin),
          "youtube" => blank_to_nil(socket.assigns.youtube),
          "x" => blank_to_nil(socket.assigns.x),
          "facebook" => blank_to_nil(socket.assigns.facebook),
          "social" => social_values(socket.assigns),
          "headshot_url" => blank_to_nil(socket.assigns.headshot_url),
          "full_body_url" => blank_to_nil(socket.assigns.full_body_url),
          "cv_url" => blank_to_nil(socket.assigns.cv_url)
        }
      }
    }

    result =
      case socket.assigns.mode do
        :edit -> Marketplace.update_listing(socket.assigns.listing, attrs)
        :clone -> Marketplace.create_listing(attrs)
        _ -> Marketplace.create_listing(attrs)
      end

    case result do
      {:ok, _listing} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           save_message(socket.assigns.mode, status)
         )
         |> push_navigate(to: "/agents")}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Listing could not be saved: #{inspect(changeset.errors)}")}
    end
  end

  defp assign_field(socket, "title", value), do: assign(socket, title: value)
  defp assign_field(socket, "summary", value), do: assign(socket, summary: value)
  defp assign_field(socket, "profession", value), do: assign(socket, profession: value)
  defp assign_field(socket, "personality", value), do: assign(socket, personality: value)
  defp assign_field(socket, "content", value), do: assign(socket, content: value)
  defp assign_field(socket, "age", value), do: assign(socket, age: value)
  defp assign_field(socket, "gender", value), do: assign(socket, gender: value)
  defp assign_field(socket, "country", value), do: assign(socket, country: value)
  defp assign_field(socket, "city", value), do: assign(socket, city: value)
  defp assign_field(socket, "email", value), do: assign(socket, email: value)
  defp assign_field(socket, "phone", value), do: assign(socket, phone: value)
  defp assign_field(socket, "telegram", value), do: assign(socket, telegram: value)
  defp assign_field(socket, "whatsapp", value), do: assign(socket, whatsapp: value)
  defp assign_field(socket, "height_cm", value), do: assign(socket, height_cm: value)
  defp assign_field(socket, "weight_kg", value), do: assign(socket, weight_kg: value)
  defp assign_field(socket, "instagram", value), do: assign(socket, instagram: value)
  defp assign_field(socket, "tiktok", value), do: assign(socket, tiktok: value)
  defp assign_field(socket, "linkedin", value), do: assign(socket, linkedin: value)
  defp assign_field(socket, "youtube", value), do: assign(socket, youtube: value)
  defp assign_field(socket, "x", value), do: assign(socket, x: value)
  defp assign_field(socket, "facebook", value), do: assign(socket, facebook: value)
  defp assign_field(socket, "cv_url", value), do: assign(socket, cv_url: value)
  defp assign_field(socket, "source_type", value), do: assign(socket, source_type: value)

  defp assign_field(socket, "fulfillment_mode", value),
    do: assign(socket, fulfillment_mode: value)

  defp assign_field(socket, "runtime_kind", value), do: assign(socket, runtime_kind: value)
  defp assign_field(socket, "hosting_mode", value), do: assign(socket, hosting_mode: value)
  defp assign_field(socket, "provider_url", value), do: assign(socket, provider_url: value)
  defp assign_field(socket, "headshot_url", value), do: assign(socket, headshot_url: value)
  defp assign_field(socket, "full_body_url", value), do: assign(socket, full_body_url: value)

  defp assign_field(socket, "external_setup_url", value),
    do: assign(socket, external_setup_url: value)

  defp assign_field(socket, "required_skills", value), do: assign(socket, required_skills: value)
  defp assign_field(socket, "standards", value), do: assign(socket, standards: value)

  defp assign_field(socket, "task_price_credits", value),
    do: assign(socket, task_price_credits: value)

  defp assign_field(socket, "rental_price_credits", value),
    do: assign(socket, rental_price_credits: value)

  defp assign_field(socket, "rental_period", value), do: assign(socket, rental_period: value)
  defp assign_field(socket, _field, _value), do: socket

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp parse_csv(value) do
    value
    |> to_string()
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp social_values(assigns) do
    base = parse_csv(assigns.required_skills)

    platform_names =
      [
        {"Instagram", assigns.instagram},
        {"TikTok", assigns.tiktok},
        {"Telegram", assigns.telegram},
        {"WhatsApp", assigns.whatsapp},
        {"LinkedIn", assigns.linkedin},
        {"YouTube", assigns.youtube},
        {"X", assigns.x},
        {"Facebook", assigns.facebook}
      ]
      |> Enum.filter(fn {_name, value} -> blank_to_nil(value) end)
      |> Enum.map(fn {name, _value} -> name end)

    Enum.uniq(base ++ platform_names)
  end

  defp listing_value(nil, _field, default), do: default
  defp listing_value(listing, field, default), do: Map.get(listing, field) || default

  defp csv_value(values, _default) when is_list(values) and values != [],
    do: Enum.join(values, ", ")

  defp csv_value(_values, default), do: default

  defp profile(%{metadata: %{"kadro_profile" => profile}}) when is_map(profile), do: profile
  defp profile(_listing), do: %{}
  defp profile_value(listing, key), do: Map.get(profile(listing), key)

  defp initial_title(nil, _mode), do: ""
  defp initial_title(listing, :clone), do: "#{listing.title} Copy"
  defp initial_title(listing, _mode), do: listing.title

  defp page_title(:edit), do: "Edit Agent"
  defp page_title(:clone), do: "Clone Agent"
  defp page_title(_mode), do: "List Agent"

  defp current_path(nil, _mode), do: "/listings/new"
  defp current_path(listing, :edit), do: "/listings/#{listing.id}/edit"
  defp current_path(listing, :clone), do: "/listings/#{listing.id}/clone"
  defp current_path(_listing, _mode), do: "/listings/new"

  defp save_message(:edit, "published"), do: "Listing updated and published."
  defp save_message(:edit, _status), do: "Listing updated."
  defp save_message(:clone, "published"), do: "Copy published."
  defp save_message(:clone, _status), do: "Copy saved as draft."
  defp save_message(_mode, "published"), do: "Listing published."
  defp save_message(_mode, _status), do: "Draft saved."

  @impl true
  def render(assigns) do
    ~H"""
    <div class="listing-flow">
      <header class="flow-header">
        <p class="market-kicker">Seller wizard</p>
        <h1>
          <%= case @mode do %>
            <% :edit -> %>
              Edit agent
            <% :clone -> %>
              Clone agent
            <% _ -> %>
              List an agent
          <% end %>
        </h1>
        <p>Keep the human card simple; agents get the full manifest.</p>
      </header>

      <div class="flow-steps">
        <span class={[@step >= 1 && "is-active"]}>Agent</span>
        <span class={[@step >= 2 && "is-active"]}>Runtime</span>
        <span class={[@step >= 3 && "is-active"]}>Skills</span>
        <span class={[@step >= 4 && "is-active"]}>Price</span>
      </div>

      <section class="flow-card">
        <div class="flow-card-body">
          <%= if @step == 1 do %>
            <h2>What are you listing?</h2>
            <input
              class="market-input"
              placeholder="Listing title"
              value={@title}
              phx-keyup="set"
              phx-value-field="title"
              phx-debounce="300"
            />
            <textarea
              class="market-textarea"
              placeholder="Short summary"
              phx-keyup="set"
              phx-value-field="summary"
              phx-debounce="300"
            ><%= @summary %></textarea>
            <input
              class="market-input"
              placeholder="Headshot URL"
              value={@headshot_url}
              phx-keyup="set"
              phx-value-field="headshot_url"
              phx-debounce="300"
            />
            <input
              class="market-input"
              placeholder="Profession"
              value={@profession}
              phx-keyup="set"
              phx-value-field="profession"
              phx-debounce="300"
            />
            <textarea
              class="market-textarea"
              placeholder="Personality / positioning"
              phx-keyup="set"
              phx-value-field="personality"
              phx-debounce="300"
            ><%= @personality %></textarea>
            <textarea
              class="market-textarea"
              placeholder="Work focus / content"
              phx-keyup="set"
              phx-value-field="content"
              phx-debounce="300"
            ><%= @content %></textarea>

            <div class="field-grid">
              <input
                class="market-input"
                placeholder="Age"
                value={@age}
                phx-keyup="set"
                phx-value-field="age"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Gender"
                value={@gender}
                phx-keyup="set"
                phx-value-field="gender"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Country"
                value={@country}
                phx-keyup="set"
                phx-value-field="country"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="City"
                value={@city}
                phx-keyup="set"
                phx-value-field="city"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Email"
                value={@email}
                phx-keyup="set"
                phx-value-field="email"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Phone"
                value={@phone}
                phx-keyup="set"
                phx-value-field="phone"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Telegram"
                value={@telegram}
                phx-keyup="set"
                phx-value-field="telegram"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="WhatsApp"
                value={@whatsapp}
                phx-keyup="set"
                phx-value-field="whatsapp"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Height cm"
                value={@height_cm}
                phx-keyup="set"
                phx-value-field="height_cm"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Weight kg"
                value={@weight_kg}
                phx-keyup="set"
                phx-value-field="weight_kg"
                phx-debounce="300"
              />
            </div>

            <div class="field-grid">
              <input
                class="market-input"
                placeholder="Instagram URL"
                value={@instagram}
                phx-keyup="set"
                phx-value-field="instagram"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="TikTok URL"
                value={@tiktok}
                phx-keyup="set"
                phx-value-field="tiktok"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="LinkedIn URL"
                value={@linkedin}
                phx-keyup="set"
                phx-value-field="linkedin"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="YouTube URL"
                value={@youtube}
                phx-keyup="set"
                phx-value-field="youtube"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="X URL"
                value={@x}
                phx-keyup="set"
                phx-value-field="x"
                phx-debounce="300"
              />
              <input
                class="market-input"
                placeholder="Facebook URL"
                value={@facebook}
                phx-keyup="set"
                phx-value-field="facebook"
                phx-debounce="300"
              />
            </div>

            <input
              class="market-input"
              placeholder="External CV URL"
              value={@cv_url}
              phx-keyup="set"
              phx-value-field="cv_url"
              phx-debounce="300"
            />
            <input
              class="market-input"
              placeholder="Full body preview URL"
              value={@full_body_url}
              phx-keyup="set"
              phx-value-field="full_body_url"
              phx-debounce="300"
            />
            <div class="choice-grid">
              <button
                :for={
                  {label, value} <- [
                    {"My agent", "seller_agent"},
                    {"Persona", "internal_persona"},
                    {"Provider", "third_party_provider"}
                  ]
                }
                class={["choice-button", @source_type == value && "is-selected"]}
                phx-click="select"
                phx-value-field="source_type"
                phx-value-value={value}
              >
                {label}
              </button>
            </div>
          <% end %>

          <%= if @step == 2 do %>
            <h2>Runtime and hosting</h2>
            <select
              class="market-input"
              phx-change="select"
              phx-value-field="runtime_kind"
              name="value"
            >
              <option
                :for={runtime <- @runtimes}
                value={runtime.id}
                selected={@runtime_kind == runtime.id}
              >
                {runtime.name}
              </option>
            </select>
            <div class="choice-grid is-four">
              <button
                :for={
                  {label, value} <- [
                    {"Hosted", "hosted"},
                    {"Unhosted", "unhosted"},
                    {"Provider", "external_provider"},
                    {"Self-hosted", "self_hosted"}
                  ]
                }
                class={["choice-button", @hosting_mode == value && "is-selected"]}
                phx-click="select"
                phx-value-field="hosting_mode"
                phx-value-value={value}
              >
                {label}
              </button>
            </div>
            <input
              class="market-input"
              placeholder="Provider URL"
              value={@provider_url}
              phx-keyup="set"
              phx-value-field="provider_url"
              phx-debounce="300"
            />
            <input
              class="market-input"
              placeholder="Setup URL"
              value={@external_setup_url}
              phx-keyup="set"
              phx-value-field="external_setup_url"
              phx-debounce="300"
            />
          <% end %>

          <%= if @step == 3 do %>
            <h2>Skills and standards</h2>
            <input
              class="market-input"
              value={@required_skills}
              phx-keyup="set"
              phx-value-field="required_skills"
              phx-debounce="300"
            />
            <input
              class="market-input"
              value={@standards}
              phx-keyup="set"
              phx-value-field="standards"
              phx-debounce="300"
            />
          <% end %>

          <%= if @step == 4 do %>
            <h2>Pricing</h2>
            <input
              class="market-input"
              type="number"
              min="0"
              value={@task_price_credits}
              phx-keyup="set"
              phx-value-field="task_price_credits"
              phx-debounce="300"
            />
            <input
              class="market-input"
              type="number"
              min="0"
              value={@rental_price_credits}
              phx-keyup="set"
              phx-value-field="rental_price_credits"
              phx-debounce="300"
            />
            <select
              class="market-input"
              phx-change="select"
              phx-value-field="rental_period"
              name="value"
            >
              <option value="weekly" selected={@rental_period == "weekly"}>Weekly</option>
              <option value="monthly" selected={@rental_period == "monthly"}>Monthly</option>
              <option value="yearly" selected={@rental_period == "yearly"}>Yearly</option>
            </select>
          <% end %>

          <div class="flow-actions">
            <button class="action-muted" phx-click="back" disabled={@step == 1}>Back</button>
            <div>
              <%= if @step < 4 do %>
                <button class="market-primary-action" phx-click="next">Next</button>
              <% else %>
                <button class="action-muted" phx-click="save" phx-value-status="draft">
                  Save draft
                </button>
                <button class="market-primary-action" phx-click="save" phx-value-status="published">
                  Publish
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
