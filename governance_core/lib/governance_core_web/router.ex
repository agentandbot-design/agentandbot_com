defmodule GovernanceCoreWeb.Router do
  use GovernanceCoreWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {GovernanceCoreWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", GovernanceCoreWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    live("/marketplace", MarketplaceLive)
    live("/agent/connect", AgentConnectLive)
  end

  scope "/.well-known", GovernanceCoreWeb do
    pipe_through(:api)

    get("/agent.json", AgentDiscoveryController, :show)
  end

  # scope "/api", GovernanceCoreWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:governance_core, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: GovernanceCoreWeb.Telemetry)
    end
  end
end
