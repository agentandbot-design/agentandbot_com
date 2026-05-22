defmodule GovernanceCore.RuntimeCatalogTest do
  use ExUnit.Case, async: true

  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.RuntimeCatalog

  test "every runtime exposes required marketplace metadata" do
    for runtime <- RuntimeCatalog.runtimes() do
      assert runtime.id
      assert runtime.name
      assert is_list(runtime.standards) and runtime.standards != []
      assert is_list(runtime.default_skills) and runtime.default_skills != []
      assert is_list(runtime.hosting_options) and runtime.hosting_options != []

      if runtime.id != "custom_webhook" do
        assert runtime.source_url
      end
    end
  end

  test "runtime ids are accepted by persona changeset" do
    for runtime <- RuntimeCatalog.runtimes() do
      changeset =
        Persona.changeset(%Persona{}, %{
          name: "#{runtime.name} Test",
          sub_type: "bot",
          access_group: "external",
          status: "active",
          runtime_kind: runtime.id
        })

      assert changeset.valid?
    end
  end

  test "key runtimes expose framework-specific standards" do
    google = RuntimeCatalog.get_runtime("google_agent")
    assert "UCP" in google.standards
    assert "AP2" in google.standards

    hermes = RuntimeCatalog.get_runtime("hermes")
    assert "ACP" in hermes.standards
    assert "SOUL.md" in hermes.standards
    assert "MEMORY.md" in hermes.standards

    agent_zero = RuntimeCatalog.get_runtime("agent_zero")
    assert "Ed25519" in agent_zero.standards
    assert "identity.json" in agent_zero.standards

    manus = RuntimeCatalog.get_runtime("manus_style")
    assert "SKILL.md" in manus.standards
    assert "sandboxed_tools" in manus.standards

    openclaw = RuntimeCatalog.get_runtime("openclaw")
    assert "A2A v0.3.0" in openclaw.standards
    assert "workspace_gateway" in openclaw.standards
  end
end
