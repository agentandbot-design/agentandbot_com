defmodule GovernanceCore.InternalTools do
  @moduledoc """
  Registry for e-any.online internal tools.

  This context stores and exposes tool metadata only. Credentials, invite
  tokens, cookies, and admin passwords must live in an external vault.
  """

  import Ecto.Query

  alias GovernanceCore.{InternalTools.InternalTool, PublicServices}
  alias GovernanceCore.Repo

  @default_tools [
    PublicServices.cv_generator_internal_tool(),
    %{
      slug: "ai-webui",
      name: "Open WebUI",
      url: "https://ai.e-any.online/",
      container_name: "ai-webui",
      category: "ai_interface",
      owner: "internal_ops",
      audience: ["internal_team"],
      agent_access: "false",
      status: "active",
      auth_mode: "password_or_sso",
      health: "healthy",
      data_classification: "internal",
      secrets_ref: "vault://e-any/ai-webui/admin",
      notes: "LLM web interface for internal users."
    },
    %{
      slug: "ai-ollama",
      name: "Ollama",
      url: "internal://ai-ollama:11434",
      container_name: "ai-ollama",
      category: "model_runtime",
      owner: "internal_ops",
      audience: ["agents", "internal_team"],
      agent_access: "true",
      status: "active",
      auth_mode: "private_network",
      health: "running",
      data_classification: "internal",
      secrets_ref: "vault://e-any/ai-ollama/service-token",
      allowed_agent_scopes: ["model:invoke"],
      notes: "Local model runtime. Keep private unless proxied with auth."
    },
    %{
      slug: "paperclip",
      name: "Paperclip",
      url: "https://paperclip.e-any.online/",
      container_name: "ai-paperclip",
      category: "agent_runtime",
      owner: "internal_ops",
      audience: ["internal_team", "agents"],
      agent_access: "true",
      status: "degraded",
      auth_mode: "password_or_invite",
      health: "restarting",
      data_classification: "internal",
      secrets_ref: "vault://e-any/paperclip/admin",
      allowed_agent_scopes: ["agent:run", "task:read"],
      notes: "Restarting in the latest observed inventory. Rotate bootstrap links."
    },
    %{
      slug: "agent-zero",
      name: "Agent Zero",
      url: "https://a0.e-any.online/",
      container_name: "agent-zero",
      category: "agent_runtime",
      owner: "internal_ops",
      audience: ["internal_team", "agents"],
      agent_access: "true",
      status: "active",
      auth_mode: "password_or_sso",
      health: "unknown",
      data_classification: "internal",
      secrets_ref: "vault://e-any/agent-zero/admin",
      allowed_agent_scopes: ["agent:run", "tools:invoke"]
    },
    %{
      slug: "space-agent",
      name: "Space Agent",
      url: "https://space.e-any.online/",
      container_name: "space-agent",
      category: "agent_runtime",
      owner: "internal_ops",
      audience: ["internal_team", "agents"],
      agent_access: "true",
      status: "active",
      auth_mode: "password_or_sso",
      health: "unknown",
      data_classification: "internal",
      secrets_ref: "vault://e-any/space-agent/admin",
      allowed_agent_scopes: ["agent:run", "tools:invoke"]
    },
    %{
      slug: "siyuan",
      name: "SiYuan",
      url: "https://notes.e-any.online/",
      internal_url: "internal://siyuan-siyuan-1:6806",
      container_name: "siyuan-siyuan-1",
      category: "knowledge_base",
      owner: "internal_ops",
      audience: ["internal_team"],
      agent_access: "false",
      status: "active",
      auth_mode: "password_or_sso",
      health: "unknown",
      data_classification: "confidential",
      secrets_ref: "vault://e-any/siyuan/admin"
    },
    %{
      slug: "windmill",
      name: "Windmill",
      url: "https://windmill.e-any.online/",
      container_name: "windmill-server",
      category: "workflow_automation",
      owner: "internal_ops",
      audience: ["internal_team", "agents"],
      agent_access: "true",
      status: "active",
      auth_mode: "sso_or_service_token",
      health: "running",
      data_classification: "internal",
      allowed_agent_scopes: ["workflow:run", "job:read", "mcp:invoke"],
      secrets_ref: "vault://e-any/windmill/admin",
      notes:
        "Workflow automation hub. Agents should use scoped service tokens or the MCP token stored in vault/env.",
      metadata: %{
        "workspace" => "admins",
        "mcp_path" => "/api/mcp/w/admins/mcp",
        "mcp_token_policy" => "vault_or_env_only",
        "recommended_flows_endpoint" => "/api/internal-tools/windmill/flows"
      }
    },
    %{
      slug: "activepieces",
      name: "Activepieces",
      url: "https://cloud.activepieces.com/",
      container_name: "activepieces-cloud",
      category: "workflow_automation",
      owner: "content_ops",
      audience: ["internal_team", "agents"],
      agent_access: "true",
      status: "active",
      auth_mode: "oauth_mcp",
      health: "managed_cloud",
      data_classification: "internal",
      allowed_agent_scopes: ["workflow:run", "mcp:invoke", "social:write", "forms:read"],
      secrets_ref: "vault://e-any/activepieces/oauth",
      notes:
        "OAuth-based MCP-compatible automation hub for SaaS, social, form, and connector-heavy workflows.",
      metadata: %{
        "mcp_url" => "https://cloud.activepieces.com/mcp/platform",
        "oauth_managed_by" => "mcp_client",
        "recommended_flows_endpoint" => "/api/internal-tools/activepieces/flows"
      }
    },
    %{
      slug: "portainer",
      name: "Portainer",
      url: "https://portainer.e-any.online/",
      container_name: "admin-portainer",
      category: "admin",
      owner: "ops_admins",
      audience: ["ops_admins"],
      agent_access: "false",
      status: "active",
      auth_mode: "sso_or_admin_password",
      health: "running",
      data_classification: "restricted",
      secrets_ref: "vault://e-any/portainer/admin"
    },
    %{
      slug: "uptime-kuma",
      name: "Uptime Kuma",
      url: "https://uptime.e-any.online/",
      container_name: "admin-uptime",
      category: "monitoring",
      owner: "ops_admins",
      audience: ["internal_team", "ops_admins"],
      agent_access: "read_only",
      status: "active",
      auth_mode: "sso_or_password",
      health: "healthy",
      data_classification: "internal",
      secrets_ref: "vault://e-any/uptime-kuma/admin"
    },
    %{
      slug: "netdata",
      name: "Netdata",
      url: "https://netdata.e-any.online/",
      container_name: "admin-netdata",
      category: "monitoring",
      owner: "ops_admins",
      audience: ["ops_admins"],
      agent_access: "read_only",
      status: "active",
      auth_mode: "sso_or_password",
      health: "healthy",
      data_classification: "restricted",
      secrets_ref: "vault://e-any/netdata/admin"
    },
    %{
      slug: "nginx-proxy-manager",
      name: "Nginx Proxy Manager",
      url: "https://nginx-admin.e-any.online/",
      internal_url: "internal://core-nginx:81",
      container_name: "core-nginx",
      category: "edge_proxy",
      owner: "ops_admins",
      audience: ["ops_admins"],
      agent_access: "false",
      status: "active",
      auth_mode: "admin_password",
      health: "running",
      data_classification: "restricted",
      secrets_ref: "vault://e-any/nginx-proxy-manager/admin"
    },
    %{
      slug: "postgres",
      name: "PostgreSQL",
      url: "internal://core-postgres:5432",
      container_name: "core-postgres",
      category: "database",
      owner: "ops_admins",
      audience: ["ops_admins", "apps"],
      agent_access: "scoped_service_accounts_only",
      status: "active",
      auth_mode: "service_account",
      health: "running",
      data_classification: "restricted",
      secrets_ref: "vault://e-any/postgres/admin",
      allowed_agent_scopes: ["db:read_limited"]
    },
    %{
      slug: "redis",
      name: "Redis",
      url: "internal://core-redis:6379",
      container_name: "core-redis",
      category: "cache",
      owner: "ops_admins",
      audience: ["apps"],
      agent_access: "false",
      status: "active",
      auth_mode: "private_network",
      health: "running",
      data_classification: "internal",
      secrets_ref: "vault://e-any/redis/service-token"
    }
  ]

  def list_tools(opts \\ []) do
    persisted =
      InternalTool
      |> maybe_filter_category(Keyword.get(opts, :category, "all"))
      |> maybe_filter_agent_access(Keyword.get(opts, :agent_access, "all"))
      |> Repo.all()
      |> Enum.map(&to_public_map/1)

    merge_with_defaults(persisted, opts)
  rescue
    _ -> default_tools(opts)
  end

  def get_tool(slug) do
    case Enum.find(list_tools(), &(&1.slug == slug)) do
      nil -> nil
      tool -> tool
    end
  end

  def categories do
    list_tools()
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def create_tool(attrs) do
    %InternalTool{}
    |> InternalTool.changeset(attrs)
    |> Repo.insert()
  end

  def to_public_map(%InternalTool{} = tool) do
    tool
    |> Map.take([
      :id,
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
  end

  def to_public_map(tool) when is_map(tool), do: tool

  defp default_tools(opts) do
    @default_tools
    |> Enum.map(&Map.put_new(&1, :allowed_agent_scopes, []))
    |> Enum.map(&Map.put_new(&1, :metadata, %{}))
    |> Enum.map(&Map.put_new(&1, :notes, nil))
    |> Enum.map(&Map.put_new(&1, :internal_url, nil))
    |> filter_default_category(Keyword.get(opts, :category, "all"))
    |> filter_default_agent_access(Keyword.get(opts, :agent_access, "all"))
  end

  defp merge_with_defaults([], opts), do: default_tools(opts)

  defp merge_with_defaults(persisted, opts) do
    defaults_by_slug = Map.new(default_tools([]), &{&1.slug, &1})

    persisted_by_slug =
      persisted
      |> Enum.map(fn tool ->
        default = Map.get(defaults_by_slug, tool.slug, %{})

        clean_tool =
          tool
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Map.new()

        merged = Map.merge(default, clean_tool)
        {merged.slug, merged}
      end)
      |> Map.new()

    defaults_by_slug
    |> Map.merge(persisted_by_slug)
    |> Map.values()
    |> filter_default_category(Keyword.get(opts, :category, "all"))
    |> filter_default_agent_access(Keyword.get(opts, :agent_access, "all"))
  end

  defp maybe_filter_category(query, value) when value in [nil, "", "all"], do: query
  defp maybe_filter_category(query, value), do: where(query, [t], t.category == ^value)

  defp maybe_filter_agent_access(query, value) when value in [nil, "", "all"], do: query
  defp maybe_filter_agent_access(query, "yes"), do: where(query, [t], t.agent_access != "false")
  defp maybe_filter_agent_access(query, value), do: where(query, [t], t.agent_access == ^value)

  defp filter_default_category(tools, value) when value in [nil, "", "all"], do: tools
  defp filter_default_category(tools, value), do: Enum.filter(tools, &(&1.category == value))

  defp filter_default_agent_access(tools, value) when value in [nil, "", "all"], do: tools

  defp filter_default_agent_access(tools, "yes"),
    do: Enum.filter(tools, &(&1.agent_access != "false"))

  defp filter_default_agent_access(tools, value),
    do: Enum.filter(tools, &(&1.agent_access == value))

  @doc """
  Parses a lightweight YAML format, extracting list of tools under `tools:`.
  """
  def parse_yaml(content) do
    lines = String.split(content, ~r/\r?\n/)

    {tools, current_tool} =
      Enum.reduce(lines, {[], nil}, fn line, {acc, cur} ->
        trimmed = String.trim(line)

        cond do
          trimmed == "" or String.starts_with?(trimmed, "#") ->
            {acc, cur}

          # Start of a new tool
          String.starts_with?(trimmed, "- slug:") ->
            acc = if cur, do: [cur | acc], else: acc
            slug_val = parse_value(String.replace_prefix(trimmed, "- slug:", ""))
            {acc, %{slug: slug_val}}

          # Other keys within a tool
          cur != nil and String.contains?(trimmed, ":") ->
            [key, val_str] = String.split(trimmed, ":", parts: 2)
            key = String.trim(key)
            val = parse_value(String.trim(val_str))

            {key, val} =
              case key do
                "container" ->
                  {"container_name", val}

                "agent_access" ->
                  val =
                    case val do
                      true -> "true"
                      false -> "false"
                      other -> to_string(other)
                    end

                  {"agent_access", val}

                other ->
                  {other, val}
              end

            key_atom =
              try do
                String.to_existing_atom(key)
              rescue
                _ -> String.to_atom(key)
              end

            {acc, Map.put(cur, key_atom, val)}

          true ->
            {acc, cur}
        end
      end)

    tools = if current_tool, do: [current_tool | tools], else: tools
    Enum.reverse(tools)
  end

  defp parse_value(str) do
    str = String.trim(str)

    cond do
      # Bracketed list: [item1, item2]
      String.starts_with?(str, "[") and String.ends_with?(str, "]") ->
        str
        |> trim_wrapping_chars()
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&strip_quotes/1)

      # Quoted string
      String.starts_with?(str, "\"") and String.ends_with?(str, "\"") ->
        trim_wrapping_chars(str)

      String.starts_with?(str, "'") and String.ends_with?(str, "'") ->
        trim_wrapping_chars(str)

      # Booleans
      str == "true" ->
        true

      str == "false" ->
        false

      # Otherwise, return string
      true ->
        str
    end
  end

  defp strip_quotes(str) do
    cond do
      String.starts_with?(str, "\"") and String.ends_with?(str, "\"") -> trim_wrapping_chars(str)
      String.starts_with?(str, "'") and String.ends_with?(str, "'") -> trim_wrapping_chars(str)
      true -> str
    end
  end

  defp trim_wrapping_chars(str) do
    str
    |> String.slice(1, max(String.length(str) - 2, 0))
    |> to_string()
  end

  @doc """
  Reads YAML manifest file and synchronizes tools to the database.
  """
  def sync_from_yaml(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      tools = parse_yaml(content)

      Enum.each(tools, fn attrs ->
        slug = attrs[:slug]

        case Repo.get_by(InternalTool, slug: slug) do
          nil ->
            case create_tool(attrs) do
              {:ok, _tool} ->
                :ok

              {:error, changeset} ->
                IO.inspect(changeset.errors, label: "Error creating internal tool from YAML")
            end

          existing ->
            existing
            |> InternalTool.changeset(attrs)
            |> Repo.update()
        end
      end)

      {:ok, length(tools)}
    else
      {:error, :file_not_found}
    end
  end
end
