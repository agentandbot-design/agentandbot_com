defmodule GovernanceCoreWeb.GovernanceLive do
  use GovernanceCoreWeb, :live_view

  def mount(_params, _session, socket) do
    # MOCK DATA: AP2 Mandates and x402 Challenges
    wallet = %{
      balance_usdc: 1250.75,
      reserved_escrow: 50.00,
      monthly_limit: 500.00
    }

    mandates = [
      %{
        id: "m1",
        persona: "Creative Writer",
        limit: "50 USDC/mo",
        usage: "12 USDC",
        status: "active"
      },
      %{
        id: "m2",
        persona: "Jules Monitoring",
        limit: "Unlimited (Harezm)",
        usage: "85k tokens",
        status: "internal"
      }
    ]

    challenges = [
      %{id: "c1", persona_name: "DataScraper Pro", amount: 0.45, task_name: "LinkedIn Search"},
      %{id: "c2", persona_name: "External Bot X", amount: 1.20, task_name: "API Transcription"}
    ]

    {:ok,
     assign(socket,
       wallet: wallet,
       mandates: mandates,
       challenges: challenges,
       page_title: "Governance & Wallet",
       current_path: "/governance"
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="governance-wallet" class="space-y-10">
      <%!-- WALLET HEADER --%>
      <header class="grid grid-cols-1 md:grid-cols-3 gap-6 p-8 rounded-3xl bg-primary text-primary-content shadow-xl shadow-primary/20">
        <div class="col-span-1 border-r border-primary-content/10">
          <p class="text-[10px] font-bold uppercase tracking-widest opacity-60">Total Balance</p>
          <div class="text-4xl font-black mt-2">
            {@wallet.balance_usdc} <span class="text-lg opacity-60">USDC</span>
          </div>
        </div>

        <div class="col-span-1 border-r border-primary-content/10 px-0 md:px-6">
          <p class="text-[10px] font-bold uppercase tracking-widest opacity-60">Escrowed (Pending)</p>
          <div class="text-2xl font-bold mt-2">
            {@wallet.reserved_escrow} <span class="text-sm opacity-60">USDC</span>
          </div>
        </div>

        <div class="col-span-1 px-0 md:px-6">
          <p class="text-[10px] font-bold uppercase tracking-widest opacity-60">Monthly Limit Used</p>
          <progress
            class="progress progress-secondary w-full mt-3 h-2"
            value="245"
            max={@wallet.monthly_limit}
          >
          </progress>
          <p class="text-[10px] mt-2 opacity-60 font-mono text-right">
            49% OF {@wallet.monthly_limit} USDC
          </p>
        </div>
      </header>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-10">
        <%!-- ACTIVE CHALLENGES (x402) --%>
        <section id="payment-challenges" class="space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 px-2 flex items-center gap-2 text-warning">
            <.icon name="hero-scale" class="size-4" /> Pending x402 Challenges
          </h3>

          <div class="space-y-4">
            <div
              :if={Enum.empty?(@challenges)}
              class="alert bg-base-200 border-base-content/5 opacity-50"
            >
              <span class="text-xs italic">No pending payment challenges.</span>
            </div>
            <.challenge_alert :for={challenge <- @challenges} challenge={challenge} />
          </div>
        </section>

        <%!-- AP2 MANDATES --%>
        <section id="governance-mandates" class="space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 px-2 flex items-center gap-2">
            <.icon name="hero-bookmark-square" class="size-4" /> Active Mandates (AP2)
          </h3>

          <div class="overflow-x-auto rounded-xl border border-base-content/5 bg-base-200 shadow-sm">
            <table class="table table-md">
              <thead>
                <tr class="text-[10px] uppercase tracking-widest border-base-content/5">
                  <th>Persona</th>
                  <th>Spending Limit</th>
                  <th>Current Usage</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody class="text-xs font-medium">
                <tr
                  :for={mandate <- @mandates}
                  class="border-base-content/5 hover:bg-base-content/5 transition-colors"
                >
                  <td>{mandate.persona}</td>
                  <td>{mandate.limit}</td>
                  <td>{mandate.usage}</td>
                  <td>
                    <span class={[
                      "badge badge-xs",
                      mandate.status == "internal" && "badge-secondary",
                      mandate.status == "active" && "badge-success"
                    ]}>
                      {mandate.status}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <button class="btn btn-ghost btn-sm text-[10px] uppercase font-bold tracking-widest w-full border border-dashed border-base-content/10">
            + New AP2 Mandate Request
          </button>
        </section>
      </div>
    </div>
    """
  end
end
