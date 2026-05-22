defmodule GovernanceCore.ProtocolCatalogTest do
  use ExUnit.Case, async: true

  alias GovernanceCore.ProtocolCatalog

  test "protocol catalog exposes required protocols with discovery metadata" do
    protocols = ProtocolCatalog.protocols()
    names = Enum.map(protocols, & &1.name)

    for name <- [
          "MCP",
          "A2A",
          "ACP",
          "ANP",
          "UCP",
          "AP2",
          "DID",
          "Ed25519",
          "OpenAPI 3.1",
          "JSON Schema",
          "x402"
        ] do
      assert name in names
    end

    for protocol <- protocols do
      assert protocol.id
      assert protocol.name
      assert protocol.domain
      assert protocol.purpose
      assert protocol.status
      assert is_list(protocol.discovery_paths)
      assert is_list(protocol.supported_by_runtimes)
    end
  end
end
