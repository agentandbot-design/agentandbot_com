defmodule GovernanceCoreWeb.PaymentDashboardLive do
  use GovernanceCoreWeb, :live_view
  alias GovernanceCore.Payment.Payments

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(30_000, self(), :tick)

    {:ok, assign_stats(socket)}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign_stats(socket)}
  end

  defp assign_stats(socket) do
    total_usdc = Payments.sum_confirmed_amount()
    active_subs = Payments.count_active_subscriptions()
    requests_today = Payments.count_requests_today()
    recent_txs = Payments.list_recent_transactions(20)

    assign(socket,
      total_usdc: total_usdc,
      active_subs: active_subs,
      requests_today: requests_today,
      recent_txs: recent_txs,
      last_updated: DateTime.utc_now(),
      page_title: "Payment Dashboard",
      current_path: "/payment/dashboard"
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-6 py-10 max-w-7xl mx-auto">
      <div class="flex items-center justify-between mb-10">
        <div>
          <h1 class="text-3xl font-black tracking-tighter text-slate-900 mb-2 uppercase">
            AgentAndBot Dashboard
          </h1>
          <p class="text-xs font-mono text-slate-500 uppercase tracking-widest">
            Financial Monitoring Infrastructure
          </p>
        </div>
        <div class="text-right">
          <p class="text-[10px] font-mono text-slate-400 uppercase">Last Sync</p>
          <p class="text-xs font-mono font-bold text-emerald-600">
            {Calendar.strftime(@last_updated, "%H:%M:%S")} UTC
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <div class="bg-white border border-slate-100 rounded-3xl p-8 shadow-sm">
          <p class="text-[10px] font-mono text-slate-400 uppercase tracking-[0.2em] mb-4">
            Total Revenue
          </p>
          <div class="flex items-baseline gap-2">
            <span class="text-4xl font-black text-slate-900">${Decimal.to_string(@total_usdc)}</span>
            <span class="text-xs font-bold text-slate-400">USDC</span>
          </div>
        </div>

        <div class="bg-white border border-slate-100 rounded-3xl p-8 shadow-sm">
          <p class="text-[10px] font-mono text-slate-400 uppercase tracking-[0.2em] mb-4">
            Active Subscriptions
          </p>
          <div class="flex items-baseline gap-2">
            <span class="text-4xl font-black text-slate-900">{@active_subs}</span>
            <span class="text-xs font-bold text-slate-400">USERS</span>
          </div>
        </div>

        <div class="bg-white border border-slate-100 rounded-3xl p-8 shadow-sm">
          <p class="text-[10px] font-mono text-slate-400 uppercase tracking-[0.2em] mb-4">
            Requests Today
          </p>
          <div class="flex items-baseline gap-2">
            <span class="text-4xl font-black text-slate-900">{@requests_today}</span>
            <span class="text-xs font-bold text-slate-400">CALLS</span>
          </div>
        </div>
      </div>

      <div class="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden">
        <div class="px-8 py-6 border-b border-slate-50 flex items-center justify-between bg-slate-50/50">
          <h2 class="text-sm font-black text-slate-900 uppercase tracking-widest">
            Recent Transactions
          </h2>
          <span class="bg-emerald-100 text-emerald-700 text-[9px] font-mono px-2 py-1 rounded-full uppercase font-bold">
            Live Feed
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="bg-slate-50/30">
                <th class="px-8 py-4 text-[10px] font-mono text-slate-400 uppercase">TX Hash</th>
                <th class="px-8 py-4 text-[10px] font-mono text-slate-400 uppercase">Chain</th>
                <th class="px-8 py-4 text-[10px] font-mono text-slate-400 uppercase">Amount</th>
                <th class="px-8 py-4 text-[10px] font-mono text-slate-400 uppercase">Status</th>
                <th class="px-8 py-4 text-[10px] font-mono text-slate-400 uppercase">Date</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
              <%= for tx <- @recent_txs do %>
                <tr class="hover:bg-slate-50/50 transition-colors">
                  <td class="px-8 py-4 font-mono text-xs text-slate-600">
                    {String.slice(tx.tx_hash, 0, 10)}...
                  </td>
                  <td class="px-8 py-4">
                    <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      {tx.chain}
                    </span>
                  </td>
                  <td class="px-8 py-4 font-bold text-slate-900">
                    ${Decimal.to_string(tx.amount_usdc)}
                  </td>
                  <td class="px-8 py-4">
                    <span class={[
                      "text-[10px] font-black uppercase px-2 py-1 rounded-md",
                      tx.status == "confirmed" && "bg-emerald-50 text-emerald-700",
                      tx.status == "pending" && "bg-amber-50 text-amber-700",
                      tx.status == "failed" && "bg-red-50 text-red-700"
                    ]}>
                      {tx.status}
                    </span>
                  </td>
                  <td class="px-8 py-4 text-[10px] font-mono text-slate-400">
                    {Calendar.strftime(tx.inserted_at, "%Y-%m-%d %H:%M")}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
