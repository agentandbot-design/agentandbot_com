defmodule GovernanceCore.InternalToolsTest do
  use GovernanceCore.DataCase, async: false

  alias GovernanceCore.InternalTools

  test "lists safe default e-any tool metadata without raw credentials" do
    tools = InternalTools.list_tools()
    windmill = Enum.find(tools, &(&1.slug == "windmill"))
    cv_generator = Enum.find(tools, &(&1.slug == "cv-generator"))

    assert windmill.name == "Windmill"
    assert windmill.agent_access == "true"
    assert windmill.secrets_ref == "vault://e-any/windmill/admin"
    assert cv_generator.category == "public_service"
    assert cv_generator.metadata["public_callable"]

    serialized = inspect(tools)
    refute serialized =~ "20911980"
    refute serialized =~ "Kolay"
    refute serialized =~ "invite/"
  end

  test "rejects secret-like values in persisted tool records" do
    assert {:error, changeset} =
             InternalTools.create_tool(%{
               slug: "bad-tool",
               name: "Bad Tool",
               category: "admin",
               url: "https://example.com/invite/abcdef1234567890"
             })

    assert %{url: ["must not contain raw credentials or tokens"]} = errors_on(changeset)
  end

  test "parses lightweight YAML correctly" do
    yaml = """
    domain: e-any.online
    owner: Test Owner

    tools:
      - slug: test-tool
        name: Test Tool
        url: https://test.e-any.online/
        container: test-container
        category: utility
        audience: [test_audience, other]
        agent_access: true
        status: active
        auth_mode: private_network
        health: healthy
        data_classification: internal
        secrets_ref: vault://e-any/test/admin
        allowed_agent_scopes: [test:scope]
    """

    parsed = InternalTools.parse_yaml(yaml)
    assert length(parsed) == 1
    tool = hd(parsed)

    assert tool.slug == "test-tool"
    assert tool.name == "Test Tool"
    assert tool.url == "https://test.e-any.online/"
    assert tool.container_name == "test-container"
    assert tool.category == "utility"
    assert tool.audience == ["test_audience", "other"]
    assert tool.agent_access == "true"
    assert tool.status == "active"
    assert tool.auth_mode == "private_network"
    assert tool.health == "healthy"
    assert tool.data_classification == "internal"
    assert tool.secrets_ref == "vault://e-any/test/admin"
    assert tool.allowed_agent_scopes == ["test:scope"]
  end

  test "syncs tools from YAML file to database" do
    temp_yaml_path = Path.join(System.tmp_dir!(), "test_sync_tools.yml")

    yaml_content = """
    tools:
      - slug: temp-tool
        name: Temp Tool
        url: https://temp.e-any.online/
        category: helper
        audience: [agents]
        agent_access: false
    """

    File.write!(temp_yaml_path, yaml_content)

    assert {:ok, 1} = InternalTools.sync_from_yaml(temp_yaml_path)

    # Let's clean up temp file
    File.rm!(temp_yaml_path)

    tools = InternalTools.list_tools()
    temp_tool = Enum.find(tools, &(&1.slug == "temp-tool"))
    assert temp_tool != nil
    assert temp_tool.name == "Temp Tool"
    assert temp_tool.agent_access == "false"

    cv_generator = Enum.find(tools, &(&1.slug == "cv-generator"))
    assert cv_generator != nil
    assert cv_generator.category == "public_service"
  end
end
