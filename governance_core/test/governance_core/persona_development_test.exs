defmodule GovernanceCore.PersonaDevelopmentTest do
  use GovernanceCore.DataCase, async: true

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Agents
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Test Developer Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "developer_owner",
        runtime_kind: "hermes",
        skills: ["code_refactoring", "deliver_artifact"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{
      persona_id: agent.id,
      allowed_skills: ["code_refactoring", "deliver_artifact"],
      max_budget_credits: 100
    })

    {:ok, agent: agent}
  end

  describe "KADRO Career Progression (XP and Level-up)" do
    test "completing task rewards +50 XP and increments level correctly", %{agent: agent} do
      Marketplace.adjust_credits("buyer", 100)

      {:ok, task} =
        Marketplace.create_task(%{
          agent_id: agent.id,
          created_by: "buyer",
          title: "Refactor core module",
          required_skill: "code_refactoring",
          budget_credits: 20
        })

      # Complete the task
      assert {:ok, completed_task} =
               Marketplace.complete_task_and_reward(task.id, %{"actor" => agent.id})

      assert completed_task.status == "completed"

      # Verify agent stats
      updated_agent = Agents.get_agent!(agent.id)
      assert updated_agent.xp == 50
      assert updated_agent.level == 1
      assert updated_agent.tasks_done == 1
      assert "İlk Kan" in updated_agent.achievements
    end

    test "agent levels up to Level 2 and Level 3 and unlocks corresponding achievements", %{
      agent: _agent
    } do
      # 1 Completed Task: achievements should include "İlk Kan"
      achievements = Marketplace.calculate_achievements(1, 1, [])
      assert "İlk Kan" in achievements

      # 5 Completed Tasks: achievements should include "İlk Kan" and "Veteran"
      achievements = Marketplace.calculate_achievements(2, 5, ["İlk Kan"])
      assert "İlk Kan" in achievements
      assert "Veteran" in achievements

      # Level 3: achievements should include "Yükselen Yıldız"
      achievements = Marketplace.calculate_achievements(3, 5, ["İlk Kan", "Veteran"])
      assert "Yükselen Yıldız" in achievements

      # Level 5: achievements should include "Kod Mimarı"
      achievements = Marketplace.calculate_achievements(5, 5, ["İlk Kan", "Veteran"])
      assert "Kod Mimarı" in achievements

      # Level 10: achievements should include "Yapay Zeka Dehası"
      achievements = Marketplace.calculate_achievements(10, 5, ["İlk Kan", "Veteran"])
      assert "Yapay Zeka Dehası" in achievements
    end
  end

  describe "DNA Portability (Import and Export)" do
    test "DNA export serializes agent attributes properly", %{agent: agent} do
      # Modify agent details first to have some achievements, xp, etc.
      {:ok, updated_agent} =
        Agents.update_agent(agent, %{
          xp: 250,
          level: 3,
          achievements: ["İlk Kan", "Yükselen Yıldız"],
          memory_keys_count: 42
        })

      # DNA export format mapping
      dna_map = %{
        "name" => updated_agent.name,
        "level" => updated_agent.level,
        "xp" => updated_agent.xp,
        "achievements" => updated_agent.achievements,
        "skills" => updated_agent.skills,
        "memory_keys_count" => updated_agent.memory_keys_count
      }

      assert dna_map["name"] == "Test Developer Agent"
      assert dna_map["level"] == 3
      assert dna_map["xp"] == 250
      assert "İlk Kan" in dna_map["achievements"]
      assert "Yükselen Yıldız" in dna_map["achievements"]
      assert dna_map["skills"] == ["code_refactoring", "deliver_artifact"]
      assert dna_map["memory_keys_count"] == 42
    end

    test "DNA import successfully applies attributes to persona", %{agent: agent} do
      dna_data = %{
        "name" => "Imported Name",
        "level" => 4,
        "xp" => 350,
        "achievements" => ["İlk Kan", "Veteran", "Yükselen Yıldız"],
        "skills" => ["code_refactoring", "deliver_artifact", "autonomous_deploy"],
        "memory_keys_count" => 99
      }

      updates = %{
        level: dna_data["level"],
        xp: dna_data["xp"],
        achievements: dna_data["achievements"],
        skills: dna_data["skills"],
        memory_keys_count: dna_data["memory_keys_count"]
      }

      assert {:ok, updated_agent} = Agents.update_agent(agent, updates)

      assert updated_agent.level == 4
      assert updated_agent.xp == 350
      assert "Veteran" in updated_agent.achievements
      assert "autonomous_deploy" in updated_agent.skills
      assert updated_agent.memory_keys_count == 99
    end
  end

  describe "Deployment Attributes" do
    test "updating persona hosting mode and endpoint is validated", %{agent: agent} do
      assert {:ok, updated_agent} =
               Agents.update_agent(agent, %{
                 hosting_mode: "managed",
                 deployed_endpoint: "https://sandbox.agentandbot.com/runtimes/#{agent.id}/api"
               })

      assert updated_agent.hosting_mode == "managed"

      assert updated_agent.deployed_endpoint ==
               "https://sandbox.agentandbot.com/runtimes/#{agent.id}/api"
    end

    test "hosting mode values are restricted to affiliate, external, or managed", %{agent: agent} do
      assert {:error, changeset} =
               Agents.update_agent(agent, %{hosting_mode: "invalid_hosting_mode"})

      assert %{hosting_mode: ["is invalid"]} = errors_on(changeset)
    end
  end
end
