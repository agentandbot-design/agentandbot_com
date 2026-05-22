defmodule GovernanceCoreWeb.AgentControllerTest do
  use GovernanceCoreWeb.ConnCase, async: true

  alias GovernanceCore.Agents
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "DNA Test Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "agent_owner",
        runtime_kind: "hermes",
        level: 2,
        xp: 150,
        achievements: ["first_hire"],
        skills: ["deliver_artifact"],
        metadata: %{
          "kadro_profile" => %{
            "p_no" => "T-100",
            "category" => "Core",
            "profession" => "SAP Consultant",
            "private_key" => "sensitive_pk_value",
            "secret" => "super_secret"
          }
        }
      })
      |> Repo.insert!()

    {:ok, agent: agent}
  end

  test "export_dna/2 exports level, xp, achievements, skills, and sanitized kadro_profile", %{
    conn: conn,
    agent: agent
  } do
    conn = get(conn, ~p"/api/agents/#{agent.id}/dna")
    body = json_response(conn, 200)

    dna = body["data"]
    assert dna["level"] == 2
    assert dna["xp"] == 150
    assert dna["achievements"] == ["first_hire"]
    assert dna["skills"] == ["deliver_artifact"]

    kadro = dna["kadro_profile"]
    assert kadro["p_no"] == "T-100"
    assert kadro["profession"] == "SAP Consultant"

    # Verify sensitive data was filtered out!
    refute Map.has_key?(kadro, "private_key")
    refute Map.has_key?(kadro, "secret")
  end

  test "import_dna/2 applies merge upward policy and updates local agent", %{
    conn: conn,
    agent: agent
  } do
    dna_payload = %{
      "level" => 3,
      "xp" => 200,
      "achievements" => ["first_hire", "second_hire"],
      "skills" => ["deliver_artifact", "visualize"],
      "kadro_profile" => %{
        "profession" => "Lead SAP Consultant",
        "secret" => "incoming_secret"
      }
    }

    conn1 = post(conn, ~p"/api/agents/#{agent.id}/dna", %{"dna" => dna_payload})
    body1 = json_response(conn1, 200)

    updated = body1["data"]
    assert updated["level"] == 3
    assert updated["xp"] == 200
    assert updated["achievements"] == ["first_hire", "second_hire"]
    assert updated["skills"] == ["deliver_artifact", "visualize"]

    # Retrieve from DB to verify merge upward and kadro merging
    db_agent = Agents.get_agent!(agent.id)
    assert db_agent.level == 3
    assert db_agent.xp == 200
    assert db_agent.achievements == ["first_hire", "second_hire"]
    assert db_agent.skills == ["deliver_artifact", "visualize"]

    kadro_metadata = db_agent.metadata["kadro_profile"]
    assert kadro_metadata["profession"] == "Lead SAP Consultant"
    assert kadro_metadata["p_no"] == "T-100"

    # Confirm incoming secret did not overwrite and original super_secret is preserved
    assert kadro_metadata["secret"] == "super_secret"
    refute kadro_metadata["secret"] == "incoming_secret"
  end

  test "import_dna/2 does not downgrade when incoming values are lower than local values", %{
    conn: conn,
    agent: agent
  } do
    # Local: level=2, xp=150
    dna_payload = %{
      "level" => 1,
      "xp" => 50,
      "achievements" => ["first_hire"],
      "skills" => ["deliver_artifact"]
    }

    conn1 = post(conn, ~p"/api/agents/#{agent.id}/dna", %{"dna" => dna_payload})
    body1 = json_response(conn1, 200)

    updated = body1["data"]
    assert updated["level"] == 2
    assert updated["xp"] == 150
  end
end
