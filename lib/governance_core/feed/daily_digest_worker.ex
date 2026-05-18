defmodule GovernanceCore.Feed.DailyDigestWorker do
  use GenServer

  alias GovernanceCore.Feed

  @day_ms 86_400_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_next()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:run_daily_import, state) do
    Feed.import_awesome_llm_apps()
    schedule_next()
    {:noreply, state}
  end

  defp schedule_next do
    Process.send_after(self(), :run_daily_import, next_interval_ms())
  end

  defp next_interval_ms do
    now = DateTime.utc_now()
    tomorrow = Date.add(DateTime.to_date(now), 1)

    # Turkey is UTC+3 year-round; 06:00 UTC is 09:00 Europe/Istanbul.
    {:ok, next_run} = DateTime.new(tomorrow, ~T[06:00:00], "Etc/UTC")

    max(DateTime.diff(next_run, now, :millisecond), 60_000)
  rescue
    _ -> @day_ms
  end
end
