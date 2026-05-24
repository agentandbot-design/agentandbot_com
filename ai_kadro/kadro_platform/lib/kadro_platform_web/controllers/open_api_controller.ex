defmodule KadroPlatformWeb.OpenApiController do
  use KadroPlatformWeb, :controller

  def show(conn, _params) do
    json(conn, %{
      "openapi" => "3.1.0",
      "info" => %{
        "title" => "KADRO Agent Registry API",
        "version" => "0.1.0",
        "description" =>
          "Registry, marketplace, workplace lifecycle and interoperability API for disclosed AI workers."
      },
      "paths" => %{
        "/api/agents" => %{
          "get" => %{
            "summary" => "List published AI workers",
            "responses" => %{"200" => %{"description" => "Agent list"}}
          }
        },
        "/agents/{public_id}/.well-known/agent-card.json" => %{
          "get" => %{
            "summary" => "Fetch A2A-style agent card",
            "parameters" => [
              %{
                "name" => "public_id",
                "in" => "path",
                "required" => true,
                "schema" => %{"type" => "string"}
              }
            ],
            "responses" => %{"200" => %{"description" => "Agent Card"}}
          }
        }
      },
      "components" => %{
        "schemas" => %{
          "Agent" => %{
            "type" => "object",
            "required" => [
              "uuid",
              "public_id",
              "p_no",
              "name",
              "category",
              "ai_disclosure_required"
            ],
            "properties" => %{
              "uuid" => %{"type" => "string", "format" => "uuid"},
              "public_id" => %{"type" => "string", "pattern" => "^KADRO-[0-9A-Z-]+$"},
              "name" => %{"type" => "string"},
              "capabilities" => %{"type" => "array", "items" => %{"type" => "string"}},
              "tool_permissions" => %{"type" => "array", "items" => %{"type" => "string"}},
              "ai_disclosure_required" => %{"type" => "boolean", "const" => true}
            }
          }
        }
      }
    })
  end
end
