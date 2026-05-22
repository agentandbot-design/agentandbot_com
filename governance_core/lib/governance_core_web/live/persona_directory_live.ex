defmodule GovernanceCoreWeb.PersonaDirectoryLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Marketplace

  @price_ranges [
    {"Price: All", "all"},
    {"Free", "free"},
    {"1-5 cr", "1-5"},
    {"6-20 cr", "6-20"},
    {"20+ cr", "20+"}
  ]

  @actions [
    {"Action: All", "all"},
    {"Hire", "hire"},
    {"Rent", "rent"},
    {"Provider", "provider"}
  ]

  @age_ranges [
    {"Age: All", "all"},
    {"18-25", "18-25"},
    {"26-35", "26-35"},
    {"36-50", "36-50"},
    {"50+", "50+"}
  ]
  @height_ranges [
    {"Height: All", "all"},
    {"<160 cm", "under_160"},
    {"160-170", "160-170"},
    {"171-180", "171-180"},
    {"180+", "180+"}
  ]
  @weight_ranges [
    {"Weight: All", "all"},
    {"<55 kg", "under_55"},
    {"55-70", "55-70"},
    {"71-90", "71-90"},
    {"90+", "90+"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    listings =
      Marketplace.list_listings()
      |> Enum.sort_by(&sort_key/1)

    socket =
      socket
      |> assign(
        all_listings: listings,
        filters: %{
          "search" => "",
          "skill" => "all",
          "runtime" => "all",
          "hosting" => "all",
          "price" => "all",
          "action" => "all",
          "photo" => "all",
          "age" => "all",
          "country" => "all",
          "gender" => "all",
          "contact_channel" => "all",
          "height" => "all",
          "weight" => "all"
        },
        advanced_filters?: false,
        skills: option_values(listings, & &1.required_skills),
        runtimes: option_values(listings, & &1.runtime_kind),
        hostings: option_values(listings, & &1.hosting_mode),
        countries: option_values(listings, &profile_value(&1, "country")),
        genders: option_values(listings, &profile_value(&1, "gender")),
        contact_channels: contact_channels(),
        price_ranges: @price_ranges,
        actions: @actions,
        age_ranges: @age_ranges,
        height_ranges: @height_ranges,
        weight_ranges: @weight_ranges,
        page_title: "AI Worker Marketplace",
        current_path: "/agents"
      )
      |> assign_filtered_listings()

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      socket.assigns.filters
      |> Map.merge(
        Map.take(params, [
          "search",
          "skill",
          "runtime",
          "hosting",
          "price",
          "action",
          "photo",
          "age",
          "country",
          "gender",
          "contact_channel",
          "height",
          "weight"
        ])
      )

    {:noreply, socket |> assign(filters: filters) |> assign_filtered_listings()}
  end

  @impl true
  def handle_event("toggle_advanced_filters", _params, socket) do
    {:noreply, assign(socket, advanced_filters?: !socket.assigns.advanced_filters?)}
  end

  defp assign_filtered_listings(socket) do
    assign(socket, listings: filter_listings(socket.assigns.all_listings, socket.assigns.filters))
  end

  defp filter_listings(listings, filters) do
    Enum.filter(listings, fn listing ->
      matches_search?(listing, filters["search"]) and
        matches_skill?(listing, filters["skill"]) and
        matches_value?(listing.runtime_kind, filters["runtime"]) and
        matches_value?(listing.hosting_mode, filters["hosting"]) and
        matches_price?(listing.task_price_credits, filters["price"]) and
        matches_action?(listing, filters["action"]) and
        matches_photo?(listing, filters["photo"]) and
        matches_age?(profile_value(listing, "age"), filters["age"]) and
        matches_value?(profile_value(listing, "country"), filters["country"]) and
        matches_value?(profile_value(listing, "gender"), filters["gender"]) and
        matches_contact_channel?(listing, filters["contact_channel"]) and
        matches_height?(profile_value(listing, "height_cm"), filters["height"]) and
        matches_weight?(profile_value(listing, "weight_kg"), filters["weight"])
    end)
  end

  defp sort_key(listing), do: {if(has_photo?(listing), do: 0, else: 1), listing.title || ""}

  defp matches_search?(_listing, value) when value in [nil, ""], do: true

  defp matches_search?(listing, value) do
    haystack =
      [
        listing.title,
        listing.summary,
        listing.runtime_kind,
        listing.hosting_mode,
        Enum.join(listing.required_skills || [], " "),
        Enum.join(listing.standards || [], " "),
        profile_value(listing, "profession"),
        profile_value(listing, "personality"),
        profile_value(listing, "content"),
        profile_value(listing, "country"),
        profile_value(listing, "city"),
        profile_value(listing, "gender"),
        profile_value(listing, "email"),
        profile_value(listing, "phone"),
        profile_value(listing, "telegram"),
        profile_value(listing, "whatsapp"),
        profile_value(listing, "instagram"),
        profile_value(listing, "tiktok")
      ]
      |> Enum.join(" ")
      |> String.downcase()

    String.contains?(haystack, String.downcase(value))
  end

  defp matches_skill?(_listing, value) when value in [nil, "", "all"], do: true
  defp matches_skill?(listing, value), do: value in (listing.required_skills || [])

  defp matches_value?(_actual, value) when value in [nil, "", "all"], do: true
  defp matches_value?(actual, value), do: to_string(actual || "") == value

  defp matches_price?(_price, value) when value in [nil, "", "all"], do: true
  defp matches_price?(0, "free"), do: true
  defp matches_price?(price, "1-5"), do: price in 1..5
  defp matches_price?(price, "6-20"), do: price in 6..20
  defp matches_price?(price, "20+"), do: price > 20
  defp matches_price?(_price, _value), do: false

  defp matches_action?(_listing, value) when value in [nil, "", "all"], do: true
  defp matches_action?(listing, "hire"), do: supports?(listing, "task_hire")
  defp matches_action?(listing, "rent"), do: supports?(listing, "rental")

  defp matches_action?(listing, "provider"),
    do: present?(listing.provider_url) or present?(listing.external_setup_url)

  defp matches_action?(_listing, _value), do: true

  defp matches_photo?(_listing, value) when value in [nil, "", "all"], do: true
  defp matches_photo?(listing, "with_photo"), do: has_photo?(listing)
  defp matches_photo?(listing, "without_photo"), do: not has_photo?(listing)
  defp matches_photo?(_listing, _value), do: true

  defp matches_age?(_age, value) when value in [nil, "", "all"], do: true
  defp matches_age?(age, "18-25"), do: number(age) in 18..25
  defp matches_age?(age, "26-35"), do: number(age) in 26..35
  defp matches_age?(age, "36-50"), do: number(age) in 36..50
  defp matches_age?(age, "50+"), do: number(age) > 50
  defp matches_age?(_age, _value), do: true

  defp matches_contact_channel?(_listing, value) when value in [nil, "", "all"], do: true

  defp matches_contact_channel?(listing, value) do
    profile_key =
      case value do
        "phone" -> "phone"
        "telegram" -> "telegram"
        "whatsapp" -> "whatsapp"
        "instagram" -> "instagram"
        "tiktok" -> "tiktok"
        "email" -> "email"
        _ -> value
      end

    present?(profile_value(listing, profile_key))
  end

  defp matches_height?(_height, value) when value in [nil, "", "all"], do: true
  defp matches_height?(height, "under_160"), do: number(height) > 0 and number(height) < 160
  defp matches_height?(height, "160-170"), do: number(height) in 160..170
  defp matches_height?(height, "171-180"), do: number(height) in 171..180
  defp matches_height?(height, "180+"), do: number(height) > 180
  defp matches_height?(_height, _value), do: true

  defp matches_weight?(_weight, value) when value in [nil, "", "all"], do: true
  defp matches_weight?(weight, "under_55"), do: number(weight) > 0 and number(weight) < 55
  defp matches_weight?(weight, "55-70"), do: number(weight) in 55..70
  defp matches_weight?(weight, "71-90"), do: number(weight) in 71..90
  defp matches_weight?(weight, "90+"), do: number(weight) > 90
  defp matches_weight?(_weight, _value), do: true

  defp option_values(listings, getter) do
    listings
    |> Enum.flat_map(fn listing ->
      case getter.(listing) do
        values when is_list(values) -> values
        value -> [value]
      end
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp profile(%{metadata: %{"kadro_profile" => profile}}) when is_map(profile), do: profile
  defp profile(_listing), do: %{}
  defp profile_value(listing, key), do: Map.get(profile(listing), key)

  defp contact_channels do
    [
      {"Email", "email"},
      {"Phone", "phone"},
      {"Telegram", "telegram"},
      {"WhatsApp", "whatsapp"},
      {"Instagram", "instagram"},
      {"TikTok", "tiktok"}
    ]
  end

  defp has_photo?(listing),
    do:
      present?(profile_value(listing, "headshot_url")) or
        present?(profile_value(listing, "full_body_url"))

  defp present?(value), do: value not in [nil, ""]
  defp number(value) when is_integer(value), do: value

  defp number(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {number, _rest} -> number
      :error -> 0
    end
  end

  defp number(_value), do: 0

  defp profession(listing),
    do: profile_value(listing, "profession") || listing.summary || "Skill-based agent"

  defp personality(listing),
    do: profile_value(listing, "personality") || listing.summary || "Ready for marketplace tasks."

  defp content(listing),
    do: profile_value(listing, "content") || Enum.join(listing.required_skills || [], ", ")

  defp location_text(listing) do
    [profile_value(listing, "city"), profile_value(listing, "country")]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  defp details_text(listing) do
    [
      location_text(listing),
      age_gender_text(listing),
      body_text(listing),
      runtime_label(listing.runtime_kind),
      hosting_label(listing.hosting_mode)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" / ")
  end

  defp age_gender_text(listing) do
    [profile_value(listing, "age"), profile_value(listing, "gender")]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" / ")
  end

  defp body_text(listing) do
    [
      unit_text(profile_value(listing, "height_cm"), "cm"),
      unit_text(profile_value(listing, "weight_kg"), "kg")
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" / ")
  end

  defp unit_text(nil, _unit), do: nil
  defp unit_text("", _unit), do: nil
  defp unit_text(value, unit), do: "#{value} #{unit}"

  defp social(listing) do
    case profile_value(listing, "social") do
      socials when is_list(socials) and socials != [] -> socials
      _ -> listing.required_skills || []
    end
  end

  defp initials(title) do
    title
    |> to_string()
    |> String.split(" ", trim: true)
    |> Enum.map_join("", &String.first/1)
    |> String.slice(0, 2)
    |> String.upcase()
  end

  defp runtime_label("custom_webhook"), do: "Custom"
  defp runtime_label("agent_zero"), do: "Agent-Zero"
  defp runtime_label("google_agent"), do: "Google ADK"
  defp runtime_label(value), do: humanize(value)

  defp hosting_label("self_hosted"), do: "Self-hosted"
  defp hosting_label("external_provider"), do: "Provider"
  defp hosting_label(value), do: humanize(value)

  defp humanize(nil), do: ""

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp supports?(%{fulfillment_mode: mode}, action), do: mode == action or mode == "both"
  defp supports?(_, _), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <div id="worker-marketplace" class="worker-market">
      <header class="worker-hero">
        <div>
          <p class="worker-kicker">AI worker marketplace</p>
          <h1>AgentAndBot</h1>
          <p class="worker-subtitle">
            Hire, rent, configure, edit, or clone AI workers. Photo profiles are shown first; agents read the same marketplace through skills and protocol manifests.
          </p>
        </div>
        <div class="worker-hero-stat">
          <span>{@listings |> length()}</span>
          <small>matching agents</small>
        </div>
      </header>

      <section class="worker-controls">
        <form phx-change="filter" class="worker-controls-inner">
          <input
            type="search"
            name="search"
            value={@filters["search"]}
            placeholder="Search name, skill, runtime..."
            class="worker-search"
          />

          <select name="skill" class="worker-select">
            <option value="all">Skill: All</option>
            <option :for={skill <- @skills} value={skill} selected={@filters["skill"] == skill}>
              {skill}
            </option>
          </select>

          <select name="runtime" class="worker-select">
            <option value="all">Runtime: All</option>
            <option
              :for={runtime <- @runtimes}
              value={runtime}
              selected={@filters["runtime"] == runtime}
            >
              {runtime_label(runtime)}
            </option>
          </select>

          <select name="hosting" class="worker-select">
            <option value="all">Hosting: All</option>
            <option
              :for={hosting <- @hostings}
              value={hosting}
              selected={@filters["hosting"] == hosting}
            >
              {hosting_label(hosting)}
            </option>
          </select>

          <select name="price" class="worker-select">
            <option
              :for={{label, value} <- @price_ranges}
              value={value}
              selected={@filters["price"] == value}
            >
              {label}
            </option>
          </select>

          <select name="action" class="worker-select">
            <option
              :for={{label, value} <- @actions}
              value={value}
              selected={@filters["action"] == value}
            >
              {label}
            </option>
          </select>

          <select name="photo" class="worker-select">
            <option value="all" selected={@filters["photo"] == "all"}>Photo: All</option>
            <option value="with_photo" selected={@filters["photo"] == "with_photo"}>
              With photo
            </option>
            <option value="without_photo" selected={@filters["photo"] == "without_photo"}>
              No photo
            </option>
          </select>

          <button type="button" phx-click="toggle_advanced_filters" class="worker-filter-plus">
            {if @advanced_filters?, do: "-", else: "+"}
          </button>

          <div :if={@advanced_filters?} class="worker-advanced-filters">
            <select name="age" class="worker-select">
              <option
                :for={{label, value} <- @age_ranges}
                value={value}
                selected={@filters["age"] == value}
              >
                {label}
              </option>
            </select>

            <select name="country" class="worker-select">
              <option value="all">Country: All</option>
              <option
                :for={country <- @countries}
                value={country}
                selected={@filters["country"] == country}
              >
                {country}
              </option>
            </select>

            <select name="gender" class="worker-select">
              <option value="all">Gender: All</option>
              <option
                :for={gender <- @genders}
                value={gender}
                selected={@filters["gender"] == gender}
              >
                {gender}
              </option>
            </select>

            <select name="contact_channel" class="worker-select">
              <option value="all">Contact: All</option>
              <option
                :for={{label, value} <- @contact_channels}
                value={value}
                selected={@filters["contact_channel"] == value}
              >
                {label}
              </option>
            </select>

            <select name="height" class="worker-select">
              <option
                :for={{label, value} <- @height_ranges}
                value={value}
                selected={@filters["height"] == value}
              >
                {label}
              </option>
            </select>

            <select name="weight" class="worker-select">
              <option
                :for={{label, value} <- @weight_ranges}
                value={value}
                selected={@filters["weight"] == value}
              >
                {label}
              </option>
            </select>
          </div>
        </form>

        <div class="worker-category-row">
          <span class="worker-filter-note">Photos first / all published agents / numbered list</span>
          <a href="/tools" class="worker-list-action">Agent tools</a>
          <a href="/listings/new" class="worker-list-action">List worker</a>
        </div>
      </section>

      <section class="worker-grid">
        <article :for={{listing, index} <- Enum.with_index(@listings, 1)} class="worker-card">
          <div class="worker-card-header">
            <div class="worker-avatar">
              <%= if profile_value(listing, "headshot_url") do %>
                <img src={profile_value(listing, "headshot_url")} alt={"#{listing.title} headshot"} />
              <% else %>
                <span>{initials(listing.title)}</span>
              <% end %>
            </div>
            <div class="worker-meta">
              <div class="worker-no">
                <span>#{index}</span>
                <b>{runtime_label(listing.runtime_kind)}</b>
              </div>
              <h2>{listing.title}</h2>
              <p>{profession(listing)}</p>
              <small>{details_text(listing)}</small>
            </div>
          </div>

          <div class="worker-preview">
            <%= if profile_value(listing, "full_body_url") do %>
              <img src={profile_value(listing, "full_body_url")} alt={"#{listing.title} preview"} />
            <% else %>
              <div class="worker-preview-fallback">
                <span>{initials(listing.title)}</span>
              </div>
            <% end %>
            <div class="worker-preview-shade"></div>
            <span class="worker-ai-badge">AI worker persona</span>
          </div>

          <div class="worker-card-body">
            <div>
              <h3>Profile</h3>
              <p>{personality(listing)}</p>
            </div>
            <div>
              <h3>Work focus</h3>
              <p>{content(listing)}</p>
            </div>
            <div class="worker-pill-row">
              <span :for={item <- Enum.take(social(listing), 5)}>{item}</span>
            </div>
            <div class="worker-pill-row">
              <span :for={standard <- Enum.take(listing.standards || [], 6)}>{standard}</span>
            </div>
          </div>

          <footer class="worker-card-footer">
            <div class="worker-price">
              <span>Hire</span>
              <b>{listing.task_price_credits} cr</b>
            </div>
            <div class="worker-price">
              <span>Rent</span>
              <b>{listing.rental_price_credits}/mo</b>
            </div>
            <div class="worker-actions">
              <a href={"/listings/#{listing.id}/configure?action=hire"} class="worker-main-btn">
                Hire
              </a>
              <a href={"/listings/#{listing.id}/configure?action=rent"}>Rent</a>
              <a href={"/listings/#{listing.id}/edit"}>Edit</a>
              <a href={"/listings/#{listing.id}/clone"}>Clone</a>
              <%= if listing.persona_id do %>
                <a href={"/agents/#{listing.persona_id}/cv"}>CV</a>
                <a href={"/agents/#{listing.persona_id}/portfolio"}>Portfolio</a>
              <% end %>
              <%= if listing.provider_url || listing.external_setup_url do %>
                <a
                  href={listing.provider_url || listing.external_setup_url}
                  target="_blank"
                  rel="noopener"
                >
                  Provider
                </a>
              <% end %>
            </div>
          </footer>
        </article>
      </section>
    </div>
    """
  end
end
