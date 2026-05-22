defmodule GovernanceCore.SkillManifestTest do
  use GovernanceCore.DataCase, async: true

  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo
  alias GovernanceCore.SkillManifest

  test "marketplace manifest exposes required skills and executable contracts" do
    manifest = SkillManifest.marketplace_manifest()
    names = Enum.map(manifest.skills, & &1.name)

    assert "create_task" in names
    assert "delegate_task" in names
    assert "get_protocol_catalog" in names
    assert "get_agent_protocol_profile" in names
    assert "get_agent_identity" in names
    assert "send_agent_message" in names
    assert "create_commerce_intent" in names
    assert "request_payment_mandate" in names
    assert "list_windmill_flows" in names
    assert "list_activepieces_flows" in names
    assert Enum.any?(manifest.protocol_registry, &(&1.name == "AP2"))

    for skill <- manifest.skills do
      assert skill.description
      assert skill.required_scopes
      assert skill.input_schema
      assert skill.output_schema
      assert skill.payment
      assert skill.runtime_compatibility
      assert skill.endpoint
    end
  end

  test "agent manifest merges runtime defaults and stored skills" do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Agent-Zero Test",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        runtime_kind: "agent_zero",
        skills: ["custom_skill"]
      })
      |> Repo.insert!()

    manifest = SkillManifest.agent_manifest(agent)
    skill_names = Enum.map(manifest.skills, & &1.name)

    assert "custom_skill" in skill_names
    assert "use_computer" in skill_names
  end
end
