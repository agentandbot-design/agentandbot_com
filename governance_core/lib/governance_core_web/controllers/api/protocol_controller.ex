defmodule GovernanceCoreWeb.Api.ProtocolController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.ProtocolCatalog

  def index(conn, _params) do
    json(conn, %{data: ProtocolCatalog.protocols()})
  end
end
