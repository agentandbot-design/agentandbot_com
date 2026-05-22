defmodule GovernanceCoreWeb.ScenarioBoardLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Agents

  def mount(_params, _session, socket) do
    # Ensure local_user has credits to work with KADRO
    ensure_user_credits()

    # If database has no tasks, seed beautiful real tasks for existing personas
    seed_demo_tasks_if_empty()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(GovernanceCore.PubSub, "scenario_board")
    end

    # Load tasks and active user credits
    tasks = Marketplace.list_tasks()
    credits = Marketplace.available_credits("local_user")
    agents = Agents.list_agents()

    {:ok,
     assign(socket,
       tasks: tasks,
       credits: credits,
       agents: agents,
       selected_task: nil,
       console_logs: [],
       simulation_step: 0,
       show_celebration: false,
       unlocked_achievements: [],
       old_level: 1,
       new_level: 1,
       active_tab: "board",
       page_title: "KADRO Scenario Board",
       current_path: "/scenarios"
     )}
  end

  def handle_event("select_task", %{"id" => task_id}, socket) do
    task = Marketplace.get_task(task_id)

    {:noreply,
     assign(socket, selected_task: task, console_logs: get_initial_logs(task), simulation_step: 0)}
  end

  def handle_event("close_console", _, socket) do
    {:noreply, assign(socket, selected_task: nil, console_logs: [], simulation_step: 0)}
  end

  def handle_event("launch_agent", %{"id" => task_id}, socket) do
    task = Marketplace.get_task(task_id)
    agent = task.agent

    if agent && agent.deployed_endpoint && agent.deployed_endpoint != "" do
      case Marketplace.launch_real_task_runtime(task.id) do
        {:ok, updated_task} ->
          {:noreply,
           assign(socket,
             tasks: Marketplace.list_tasks(),
             selected_task: updated_task,
             console_logs: [
               "[SYSTEM] Webhook trigger payload dispatched asynchronously to #{agent.deployed_endpoint}...",
               "[SYSTEM] Awaiting real task runtime webhook callback..."
             ]
           )}

        {:error, reason} ->
          error_msg = inspect(reason)

          {:noreply,
           put_flash(socket, :error, "Real agent execution failed to launch: #{error_msg}")}
      end
    else
      case Marketplace.record_event(task_id, "working", %{
             message: "Ajan göreve başladı (Demo Modu)."
           }) do
        {:ok, task} ->
          # Refresh tasks
          tasks = Marketplace.list_tasks()

          # Start log streaming timer
          Process.send_after(self(), {:stream_log, task.id, 1}, 800)

          {:noreply,
           assign(socket,
             tasks: tasks,
             selected_task: task,
             console_logs: [
               "[SYSTEM] Sandbox container provisioning started...",
               "[SYSTEM] Agent connected to runtime shell."
             ],
             simulation_step: 1
           )}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Ajan başlatılamadı.")}
      end
    end
  end

  def handle_event("approve_task", %{"id" => task_id}, socket) do
    task = Marketplace.get_task(task_id)
    agent = task.agent

    old_level = (agent && agent.level) || 1
    old_achievements = (agent && agent.achievements) || []

    case Marketplace.complete_task_and_reward(task_id, %{
           message: "Görev kullanıcı tarafından onaylandı. Kredi ödülü dağıtıldı."
         }) do
      {:ok, completed_task} ->
        updated_agent = completed_task.agent
        new_level = (updated_agent && updated_agent.level) || 1
        new_achievements = (updated_agent && updated_agent.achievements) || []

        # Check for Level Up or Achievement Unlock celebration!
        newly_unlocked = new_achievements -- old_achievements
        has_level_up = new_level > old_level
        has_new_achievements = length(newly_unlocked) > 0

        socket =
          if has_level_up or has_new_achievements do
            assign(socket,
              show_celebration: true,
              old_level: old_level,
              new_level: new_level,
              unlocked_achievements: newly_unlocked
            )
          else
            socket
          end

        {:noreply,
         assign(socket,
           tasks: Marketplace.list_tasks(),
           credits: Marketplace.available_credits("local_user"),
           selected_task: completed_task,
           agents: Agents.list_agents()
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Görev onaylanamadı.")}
    end
  end

  def handle_event("cancel_task", %{"id" => task_id}, socket) do
    case Marketplace.record_event(task_id, "cancelled", %{
           message: "Görev iptal edildi, kredi iadesi sağlandı."
         }) do
      {:ok, task} ->
        {:noreply,
         assign(socket,
           tasks: Marketplace.list_tasks(),
           credits: Marketplace.available_credits("local_user"),
           selected_task: task
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Görev iptal edilemedi.")}
    end
  end

  def handle_event("close_celebration", _, socket) do
    {:noreply,
     assign(socket,
       show_celebration: false,
       unlocked_achievements: [],
       old_level: 1,
       new_level: 1
     )}
  end

  def handle_event("create_demo_task", %{"agent_id" => agent_id, "type" => type}, socket) do
    agent = Agents.get_agent(agent_id)

    attrs =
      case type do
        "code" ->
          %{
            "agent_id" => agent.id,
            "created_by" => "local_user",
            "title" => "Hermes Web Arayüz Optimizasyonu",
            "instructions" =>
              "Giriş sayfasındaki animasyonların performansını artırmak için CSS donanım ivmesini entegre et.",
            "required_skill" => "automation",
            "expected_artifact" => "CSS ve JS optimizasyon yaması.",
            "budget_credits" => 35
          }

        "research" ->
          %{
            "agent_id" => agent.id,
            "created_by" => "local_user",
            "title" => "Yapay Zeka Yatırım Trendleri Analizi",
            "instructions" =>
              "2026 ilk çeyreğinde AI agent girişimlerine yapılan yatırımları araştır ve raporla.",
            "required_skill" => "research",
            "expected_artifact" => "markdown_report",
            "budget_credits" => 60
          }

        _ ->
          %{
            "agent_id" => agent.id,
            "created_by" => "local_user",
            "title" => "Sosyal Medya Kampanya Planlaması",
            "instructions" =>
              "agentandbot.com lansmanı için 5 adet etkileyici X (Twitter) flood'u tasarla.",
            "required_skill" => "writing",
            "expected_artifact" => "X kampanya flood taslakları.",
            "budget_credits" => 25
          }
      end

    case Marketplace.create_task(attrs) do
      {:ok, _task} ->
        {:noreply,
         assign(socket,
           tasks: Marketplace.list_tasks(),
           credits: Marketplace.available_credits("local_user")
         )
         |> put_flash(:info, "Yeni görev başarıyla kuyruğa eklendi!")}

      {:error, changeset} ->
        error_msg =
          changeset.errors
          |> Enum.map(fn {field, {msg, _}} -> "#{field} #{msg}" end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, "Görev oluşturulamadı: #{error_msg}")}
    end
  end

  # Log streaming simulator
  def handle_info({:stream_log, task_id, step}, socket) do
    selected = socket.assigns.selected_task

    # Only continue if the user is still viewing this task in working state
    if selected && selected.id == task_id && selected.status == "working" do
      logs = socket.assigns.console_logs

      new_log = get_simulated_log(step, selected)
      updated_logs = logs ++ [new_log]

      if step < 8 do
        Process.send_after(self(), {:stream_log, task_id, step + 1}, 900)
        {:noreply, assign(socket, console_logs: updated_logs, simulation_step: step)}
      else
        # Complete simulation step - submit artifact
        artifact_content = get_mock_artifact(selected)

        case Marketplace.submit_artifact(task_id, %{
               "artifact_url" => "/artifacts/task-#{task_id}-output.md",
               "metadata" => %{
                 "portfolio" => %{
                   "public" => true,
                   "summary" =>
                     "Ajan tarafından otonom üretilen ve doğrulanan #{selected.title} görevi çıktı belgesi.",
                   "artifact_type" => "report"
                 },
                 "output" => artifact_content
               }
             }) do
          {:ok, updated_task} ->
            {:noreply,
             assign(socket,
               tasks: Marketplace.list_tasks(),
               selected_task: updated_task,
               console_logs:
                 updated_logs ++
                   [
                     "[SYSTEM] Artifact successfully submitted to escrow ledger!",
                     "[SYSTEM] Process finished with exit code 0."
                   ],
               simulation_step: 8
             )}

          {:error, _reason} ->
            {:noreply,
             assign(socket, console_logs: updated_logs ++ ["[SYSTEM] Error submitting artifact!"])}
        end
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:task_updated, %{id: task_id} = updated_task}, socket) do
    tasks = Marketplace.list_tasks()

    socket =
      if socket.assigns.selected_task && socket.assigns.selected_task.id == task_id do
        # Build logs list from all events on the task
        events = updated_task.events || []

        logs =
          events
          |> Enum.sort_by(& &1.inserted_at)
          |> Enum.map(fn event ->
            cond do
              event.event_type == "working" -> "[SYSTEM] #{event.message}"
              event.event_type == "completed" -> "[SYSTEM] #{event.message}"
              event.event_type == "failed" -> "[ERROR] #{event.message}"
              true -> "[AJAN] #{event.message}"
            end
          end)

        assign(socket, selected_task: updated_task, console_logs: logs)
      else
        socket
      end

    {:noreply, assign(socket, tasks: tasks, credits: Marketplace.available_credits("local_user"))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # Helper functions
  defp ensure_user_credits do
    credits = Marketplace.available_credits("local_user")

    if credits < 150 do
      Marketplace.adjust_credits("local_user", 1000, %{
        "reason" => "KADRO Demo Tanımlama Bakiyesi"
      })
    end
  end

  defp seed_demo_tasks_if_empty do
    case Marketplace.list_tasks() do
      [] ->
        agents = Agents.list_agents()

        if length(agents) > 0 do
          hermes = Enum.find(agents, &(&1.type == "hermes")) || List.first(agents)
          agent_zero = Enum.find(agents, &(&1.type == "agent_zero")) || List.last(agents)

          # Seed Task 1
          Marketplace.create_task(%{
            "agent_id" => hermes.id,
            "created_by" => "local_user",
            "title" => "YouTube Kampanya Senaryosu v2",
            "instructions" =>
              "Yeni yapay zeka kariyer imkanları hakkında 10 dakikalık sürükleyici bir YouTube video senaryosu yaz.",
            "required_skill" => "writing",
            "expected_artifact" => "Tamamlanmış video senaryo taslağı (Markdown)",
            "budget_credits" => 50
          })

          # Seed Task 2
          Marketplace.create_task(%{
            "agent_id" => agent_zero.id,
            "created_by" => "local_user",
            "title" => "Pazar Araştırması ve Veri Analizi",
            "instructions" =>
              "Otonom ajan ekosistemlerindeki son 6 aylık yatırım trendlerini ve büyüme verilerini araştır.",
            "required_skill" => "research",
            "expected_artifact" => "Yatırım Trendleri Markdown Raporu",
            "budget_credits" => 75
          })
        end

      _ ->
        :ok
    end
  end

  defp get_initial_logs(task) do
    case task.status do
      "escrowed" ->
        ["[SYSTEM] Ready to deploy sandbox. Standing by..."]

      "accepted" ->
        ["[SYSTEM] Ready to deploy sandbox. Standing by..."]

      "working" ->
        ["[SYSTEM] Resuming agent runtime logs..."]

      "artifact_submitted" ->
        ["[SYSTEM] Agent finished work.", "[SYSTEM] Deliverable submitted to escrow cabinet."]

      "completed" ->
        [
          "[SYSTEM] Agent finished work.",
          "[SYSTEM] Deliverable approved & funds released to agent owner ledger."
        ]

      "refunded" ->
        ["[SYSTEM] Task cancelled. Escrow refund released to local_user."]

      _ ->
        ["[SYSTEM] Offline."]
    end
  end

  defp get_simulated_log(1, _task),
    do: "[AJAN] Bellek konfigürasyonu ve vektör veri tabanı bağlantısı doğrulanıyor..."

  defp get_simulated_log(2, task), do: "[AJAN] Görev talimatları okundu: '#{task.instructions}'"

  defp get_simulated_log(3, task),
    do:
      "[AJAN] Yetenek katmanı doğrulandı: '#{task.required_skill}'. API bağlantıları açılıyor..."

  defp get_simulated_log(4, _task),
    do:
      "[AJAN] Düşünce Zinciri (Chain of Thought - CoT) başlatıldı. Alternatif adımlar değerlendiriliyor..."

  defp get_simulated_log(5, _task),
    do: "[AJAN] Google web arama kanalı üzerinden güncel veriler ve kaynaklar taranıyor..."

  defp get_simulated_log(6, _task),
    do: "[AJAN] Çıktı metni otonom olarak oluşturuluyor ve biçimlendiriliyor..."

  defp get_simulated_log(7, _task),
    do:
      "[AJAN] Kod/Rapor kalite ve güvenlik denetimleri yapılıyor (Prompt Injection ve veri sızıntısı kontrolü sıfır risk)..."

  defp get_simulated_log(_, _task),
    do: "[AJAN] Görev çıktısı başarıyla tamamlandı. Teslimat paketleniyor."

  defp get_mock_artifact(task) do
    """
    # GÖREV ÇIKTI RAPORU: #{task.title}

    **Tarih:** #{DateTime.utc_now() |> DateTime.to_date() |> Date.to_string()}
    **Ajan:** #{task.agent.name} (Seviye #{task.agent.level})
    **Durum:** Başarıyla Tamamlandı & Doğrulandı

    ## 1. Yönetici Özeti
    Bu çalışma, kullanıcı tarafından verilen talimatlar doğrultusunda otonom olarak gerçekleştirilmiştir. İlgili tüm veri kaynakları taranmış, doğrulanmış ve profesyonel formatta paketlenmiştir.

    ## 2. Gerçekleştirilen İşlemler
    - **Arama & Tarama:** #{task.instructions} konusuyla ilgili 15'ten fazla saygın kaynak analiz edilmiştir.
    - **Analiz & Taslak:** Elde edilen veriler otonom CoT (Chain of Thought) süzgecinden geçirilerek sentezlenmiştir.
    - **Kalite Kontrol:** Çıktıda doğruluk ve güvenlik denetimi yapılmıştır.

    ## 3. Elde Edilen Çıktılar
    Görevin doğası gereği talep edilen yetenek (`#{task.required_skill}`) kullanılarak premium bir taslak üretilmiştir. 

    ---
    *Harezm KADRO Otonom Ajan Yönetim Sistemi tarafından üretilmiştir.*
    """
  end

  def render(assigns) do
    ~H"""
    <div id="scenario-hub" class="space-y-6 text-base-content min-h-screen pb-20">
      <%!-- CELEBRATION MODAL OVERLAY --%>
      <%= if @show_celebration do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md animate-fade-in">
          <div class="relative max-w-md w-full bg-gradient-to-br from-neutral-900 via-neutral-950 to-primary-950/40 p-8 rounded-3xl border border-primary/30 shadow-2xl shadow-primary/20 text-center space-y-6 transform scale-100 transition-all duration-300">
            <div class="absolute -top-12 left-1/2 -translate-x-1/2 w-24 h-24 bg-gradient-to-tr from-primary to-secondary rounded-full flex items-center justify-center shadow-lg shadow-primary/40 animate-bounce">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="2"
                stroke="white"
                class="w-12 h-12"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-.778.099-1.533.284-2.253"
                />
              </svg>
            </div>

            <div class="pt-8 space-y-2">
              <h2 class="text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-primary to-secondary tracking-tight">
                TEBRİKLER!
              </h2>
              <p class="text-xs text-base-content/60 font-bold uppercase tracking-widest">
                Ajan Gelişimi Tetiklendi
              </p>
            </div>

            <%= if @new_level > @old_level do %>
              <div class="p-6 rounded-2xl bg-primary/10 border border-primary/20 flex flex-col items-center justify-center space-y-2">
                <span class="text-xs font-bold uppercase text-primary tracking-wider">
                  SEVİYE ATLANDI!
                </span>
                <div class="flex items-center gap-4 text-3xl font-black">
                  <span class="opacity-40">{@old_level}</span>
                  <span class="text-secondary">➔</span>
                  <span class="text-primary animate-pulse">{@new_level}</span>
                </div>
              </div>
            <% end %>

            <%= if length(@unlocked_achievements) > 0 do %>
              <div class="space-y-3">
                <h4 class="text-xs font-bold uppercase text-base-content/40 tracking-wider">
                  Kazanılan Yeni Başarımlar
                </h4>
                <div class="flex flex-wrap justify-center gap-2">
                  <span
                    :for={ach <- @unlocked_achievements}
                    class="px-3 md:px-4 py-2 rounded-xl bg-gradient-to-r from-amber-500/20 to-yellow-500/20 border border-amber-500/30 text-amber-300 font-bold text-xs flex items-center gap-1 shadow-sm"
                  >
                    🏆 {ach}
                  </span>
                </div>
              </div>
            <% end %>

            <p class="text-xs text-base-content/50 italic px-4">
              "Ajanın yetenekleri ve otonom çalışma zekası, kazandığı bu gelişimle daha yüksek kalibreli işleri başarmaya hazır."
            </p>

            <button
              phx-click="close_celebration"
              class="w-full btn btn-primary bg-gradient-to-r from-primary to-secondary hover:opacity-90 border-0 rounded-2xl text-white font-black tracking-wide"
            >
              Harika! Devam Et
            </button>
          </div>
        </div>
      <% end %>

      <%!-- UPPER HEADER & ACTIONS --%>
      <header class="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 bg-gradient-to-r from-neutral-900 to-neutral-950 border border-base-content/5 rounded-3xl shadow-xl">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-primary animate-pulse"></span>
            <span class="text-xs font-bold uppercase text-primary tracking-widest">
              Harezm Swarm OS
            </span>
          </div>
          <h1 class="text-3xl font-black tracking-tight text-white flex items-center gap-2">
            KADRO Senaryo & Görev Kontrolü
          </h1>
          <p class="text-xs opacity-60">
            Ajanların işe alınması, otonom simülasyonları, kariyer ilerlemeleri ve escrow yönetimi.
          </p>
        </div>
        <div class="flex items-center gap-4">
          <div class="px-4 py-3 rounded-2xl bg-neutral-950 border border-base-content/10 flex items-center gap-3 shadow-inner">
            <div class="w-8 h-8 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center">
              <span class="text-primary font-black">C</span>
            </div>
            <div>
              <span class="text-[9px] font-bold uppercase opacity-40 block tracking-wider">
                Cüzdan Bakiyesi
              </span>
              <span class="text-md font-black text-white">{@credits} Kredi</span>
            </div>
          </div>
        </div>
      </header>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <%!-- LEFT COLUMN: INTERACTIVE DEMO TASK INJECTOR --%>
        <aside class="lg:col-span-3 space-y-6">
          <div class="p-5 bg-neutral-900 border border-base-content/5 rounded-3xl space-y-4 shadow-lg">
            <h3 class="text-md font-black text-white flex items-center gap-2">
              <span>➕ Görev İşe Alımı (KADRO)</span>
            </h3>
            <p class="text-xs opacity-60">
              Sistemdeki otonom ajanlara yeni bir görev tahsis ederek KADRO career simülasyonunu başlatın.
            </p>

            <div class="space-y-4">
              <%= for agent <- @agents do %>
                <div class="p-3 rounded-2xl bg-neutral-950 border border-base-content/5 space-y-3">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-xl bg-gradient-to-tr from-primary to-secondary flex items-center justify-center text-white font-black text-xs shadow-md">
                      {String.at(agent.name, 0)}
                    </div>
                    <div class="truncate">
                      <h4 class="text-xs font-bold text-white truncate">{agent.name}</h4>
                      <span class="text-[10px] opacity-40 block">
                        Lvl {agent.level} • {agent.xp} XP
                      </span>
                    </div>
                  </div>
                  <div class="grid grid-cols-3 gap-1">
                    <button
                      phx-click="create_demo_task"
                      phx-value-agent_id={agent.id}
                      phx-value-type="write"
                      class="btn btn-xs btn-outline hover:btn-primary text-[9px] py-1 h-auto rounded-lg"
                    >
                      Yazarlık
                    </button>
                    <button
                      phx-click="create_demo_task"
                      phx-value-agent_id={agent.id}
                      phx-value-type="research"
                      class="btn btn-xs btn-outline hover:btn-secondary text-[9px] py-1 h-auto rounded-lg"
                    >
                      Araştırma
                    </button>
                    <button
                      phx-click="create_demo_task"
                      phx-value-agent_id={agent.id}
                      phx-value-type="code"
                      class="btn btn-xs btn-outline hover:btn-accent text-[9px] py-1 h-auto rounded-lg"
                    >
                      Kodlama
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="p-5 bg-gradient-to-br from-primary-950/20 via-neutral-900 to-neutral-900 border border-primary/10 rounded-3xl space-y-3 shadow-lg">
            <h4 class="text-xs font-black text-primary uppercase tracking-widest">
              KADRO Oyun Kuralları
            </h4>
            <ul class="text-[10px] space-y-2 opacity-75">
              <li class="flex items-start gap-2">
                <span class="text-primary font-bold">•</span>
                <span>
                  Her başarılı otonom görev teslimatı ajana <strong>+50 XP</strong> kazandırır.
                </span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-primary font-bold">•</span>
                <span><strong>Level = (XP / 100) + 1</strong> formülüyle seviye atlanır.</span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-primary font-bold">•</span>
                <span>
                  İlk görevde <strong>"İlk Kan"</strong>
                  unvanı, 5. görevde <strong>"Veteran"</strong>
                  unvanı açılır.
                </span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-primary font-bold">•</span>
                <span>
                  Canlı log terminali üzerinden ajanların düşünce ve işlem zincirlerini otonom izleyebilirsiniz.
                </span>
              </li>
            </ul>
          </div>
        </aside>

        <%!-- RIGHT COLUMN: KANBAN BOARD --%>
        <main class="lg:col-span-9 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <%!-- TODO STAGE --%>
            <div class="flex flex-col gap-3 min-h-[400px]">
              <div class="flex items-center justify-between px-2">
                <h3 class="text-xs font-black uppercase tracking-wider text-base-content/40">
                  Yapılacaklar (Todo)
                </h3>
                <span class="badge badge-sm badge-neutral font-black">
                  {Enum.count(@tasks, &(&1.status in ["escrowed", "accepted", "draft"]))}
                </span>
              </div>
              <div class="space-y-3 p-2 bg-neutral-900/40 rounded-2xl border border-base-content/5 min-h-[380px] flex-1">
                <%= for task <- Enum.filter(@tasks, &(&1.status in ["escrowed", "accepted", "draft"])) do %>
                  <div
                    phx-click="select_task"
                    phx-value-id={task.id}
                    class={"p-4 rounded-2xl bg-neutral-900 border transition-all cursor-pointer flex flex-col gap-3 hover:-translate-y-0.5 hover:shadow-lg shadow-md " <> if(@selected_task && @selected_task.id == task.id, do: "border-primary shadow-primary/10", else: "border-base-content/5 hover:border-primary/40")}
                  >
                    <div>
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-[9px] font-black uppercase px-2 py-0.5 rounded-md bg-primary/10 text-primary border border-primary/20">
                          {task.required_skill}
                        </span>
                        <span class="text-[10px] font-bold text-white/80">
                          🪙 {task.budget_credits}
                        </span>
                      </div>
                      <h4 class="text-xs font-black text-white leading-snug line-clamp-2">
                        {task.title}
                      </h4>
                    </div>

                    <div class="flex items-center justify-between pt-2 border-t border-white/5">
                      <div class="flex items-center gap-1.5 truncate">
                        <div class="w-4 h-4 rounded-full bg-neutral-950 flex items-center justify-center text-[7px] text-white font-black border border-white/10">
                          {String.at((task.agent && task.agent.name) || "A", 0)}
                        </div>
                        <span class="text-[9px] opacity-50 truncate">
                          {(task.agent && task.agent.name) || "Atanmamış"}
                        </span>
                      </div>
                      <span class="text-[8px] font-bold uppercase opacity-30">Console ➔</span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- IN PROGRESS STAGE --%>
            <div class="flex flex-col gap-3 min-h-[400px]">
              <div class="flex items-center justify-between px-2">
                <h3 class="text-xs font-black uppercase tracking-wider text-amber-500">
                  Çalışıyor (Working)
                </h3>
                <span class="badge badge-sm badge-warning font-black bg-amber-500/20 text-amber-500 border-amber-500/30">
                  {Enum.count(@tasks, &(&1.status == "working"))}
                </span>
              </div>
              <div class="space-y-3 p-2 bg-neutral-900/40 rounded-2xl border border-base-content/5 min-h-[380px] flex-1">
                <%= for task <- Enum.filter(@tasks, &(&1.status == "working")) do %>
                  <div
                    phx-click="select_task"
                    phx-value-id={task.id}
                    class={"p-4 rounded-2xl bg-neutral-900 border transition-all cursor-pointer flex flex-col gap-3 hover:-translate-y-0.5 hover:shadow-lg shadow-md " <> if(@selected_task && @selected_task.id == task.id, do: "border-amber-500 shadow-amber-500/10", else: "border-base-content/5 hover:border-amber-500/40")}
                  >
                    <div>
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-[9px] font-black uppercase px-2 py-0.5 rounded-md bg-amber-500/10 text-amber-500 border border-amber-500/20">
                          {task.required_skill}
                        </span>
                        <span class="text-[10px] font-bold text-white/80">
                          🪙 {task.budget_credits}
                        </span>
                      </div>
                      <h4 class="text-xs font-black text-white leading-snug line-clamp-2">
                        {task.title}
                      </h4>
                    </div>

                    <div class="flex items-center justify-between pt-2 border-t border-white/5">
                      <div class="flex items-center gap-1.5 truncate">
                        <div class="w-4 h-4 rounded-full bg-neutral-950 flex items-center justify-center text-[7px] text-white font-black border border-amber-500/30">
                          {String.at((task.agent && task.agent.name) || "A", 0)}
                        </div>
                        <span class="text-[9px] opacity-50 truncate">
                          {(task.agent && task.agent.name) || "Atanmamış"}
                        </span>
                      </div>
                      <span class="w-2 h-2 rounded-full bg-amber-500 animate-ping"></span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- REVIEW STAGE --%>
            <div class="flex flex-col gap-3 min-h-[400px]">
              <div class="flex items-center justify-between px-2">
                <h3 class="text-xs font-black uppercase tracking-wider text-secondary">
                  İnceleme (Review)
                </h3>
                <span class="badge badge-sm badge-secondary font-black bg-secondary/20 text-secondary border-secondary/30">
                  {Enum.count(@tasks, &(&1.status == "artifact_submitted"))}
                </span>
              </div>
              <div class="space-y-3 p-2 bg-neutral-900/40 rounded-2xl border border-base-content/5 min-h-[380px] flex-1">
                <%= for task <- Enum.filter(@tasks, &(&1.status == "artifact_submitted")) do %>
                  <div
                    phx-click="select_task"
                    phx-value-id={task.id}
                    class={"p-4 rounded-2xl bg-neutral-900 border transition-all cursor-pointer flex flex-col gap-3 hover:-translate-y-0.5 hover:shadow-lg shadow-md " <> if(@selected_task && @selected_task.id == task.id, do: "border-secondary shadow-secondary/10", else: "border-base-content/5 hover:border-secondary/40")}
                  >
                    <div>
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-[9px] font-black uppercase px-2 py-0.5 rounded-md bg-secondary/10 text-secondary border border-secondary/20">
                          {task.required_skill}
                        </span>
                        <span class="text-[10px] font-bold text-white/80">
                          🪙 {task.budget_credits}
                        </span>
                      </div>
                      <h4 class="text-xs font-black text-white leading-snug line-clamp-2">
                        {task.title}
                      </h4>
                    </div>

                    <div class="flex items-center justify-between pt-2 border-t border-white/5">
                      <div class="flex items-center gap-1.5 truncate">
                        <div class="w-4 h-4 rounded-full bg-neutral-950 flex items-center justify-center text-[7px] text-white font-black border border-secondary/30">
                          {String.at((task.agent && task.agent.name) || "A", 0)}
                        </div>
                        <span class="text-[9px] opacity-50 truncate">
                          {(task.agent && task.agent.name) || "Atanmamış"}
                        </span>
                      </div>
                      <span class="text-[8px] font-black uppercase text-secondary">Review ➔</span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- DONE STAGE --%>
            <div class="flex flex-col gap-3 min-h-[400px]">
              <div class="flex items-center justify-between px-2">
                <h3 class="text-xs font-black uppercase tracking-wider text-success">
                  Tamamlandı (Done)
                </h3>
                <span class="badge badge-sm badge-success font-black bg-success/20 text-success border-success/30">
                  {Enum.count(@tasks, &(&1.status == "completed"))}
                </span>
              </div>
              <div class="space-y-3 p-2 bg-neutral-900/40 rounded-2xl border border-base-content/5 min-h-[380px] flex-1">
                <%= for task <- Enum.filter(@tasks, &(&1.status == "completed")) do %>
                  <div
                    phx-click="select_task"
                    phx-value-id={task.id}
                    class={"p-4 rounded-2xl bg-neutral-900/80 border border-success/20 transition-all cursor-pointer flex flex-col gap-3 hover:-translate-y-0.5 hover:shadow-lg shadow-md opacity-85 " <> if(@selected_task && @selected_task.id == task.id, do: "border-success bg-neutral-900 shadow-success/10", else: "")}
                  >
                    <div>
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-[9px] font-black uppercase px-2 py-0.5 rounded-md bg-success/10 text-success border border-success/20">
                          {task.required_skill}
                        </span>
                        <span class="text-[10px] font-bold text-white/80">
                          🪙 {task.budget_credits}
                        </span>
                      </div>
                      <h4 class="text-xs font-black text-white leading-snug line-clamp-2 line-through opacity-60">
                        {task.title}
                      </h4>
                    </div>

                    <div class="flex items-center justify-between pt-2 border-t border-white/5">
                      <div class="flex items-center gap-1.5 truncate">
                        <div class="w-4 h-4 rounded-full bg-neutral-950 flex items-center justify-center text-[7px] text-white font-black border border-success/20">
                          {String.at((task.agent && task.agent.name) || "A", 0)}
                        </div>
                        <span class="text-[9px] opacity-50 truncate">
                          {(task.agent && task.agent.name) || "Atanmamış"}
                        </span>
                      </div>
                      <span class="text-[8px] font-black uppercase text-success">🏆 OK</span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </main>
      </div>

      <%!-- CONTROL PANEL SIDEBAR / LIVE CONSOLE DRAWER --%>
      <%= if @selected_task do %>
        <div class="fixed inset-y-0 right-0 z-40 w-full max-w-lg bg-neutral-950/95 backdrop-blur-md border-l border-white/10 shadow-2xl flex flex-col transform translate-x-0 transition-transform duration-300">
          <%!-- Console Header --%>
          <header class="p-6 bg-neutral-950 border-b border-white/5 flex items-center justify-between">
            <div class="space-y-1">
              <span class="text-[9px] font-bold uppercase text-primary tracking-widest">
                Ajan Kontrol Kabini
              </span>
              <h2 class="text-md font-black text-white">{@selected_task.title}</h2>
            </div>
            <button
              phx-click="close_console"
              class="btn btn-sm btn-circle btn-ghost text-white/70 hover:text-white"
            >
              ✕
            </button>
          </header>

          <%!-- Console Body --%>
          <div class="flex-1 overflow-y-auto p-6 space-y-6">
            <%!-- Task Spec Information --%>
            <div class="p-4 rounded-2xl bg-neutral-900 border border-white/5 space-y-3">
              <h3 class="text-xs font-black text-white uppercase tracking-wider">
                Görev Özellikleri & Escrow
              </h3>
              <div class="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span class="opacity-40 block text-[9px] uppercase">Gereken Yetenek</span>
                  <span class="font-bold text-white">{@selected_task.required_skill}</span>
                </div>
                <div>
                  <span class="opacity-40 block text-[9px] uppercase">Bütçe Kredisi</span>
                  <span class="font-bold text-white">🪙 {@selected_task.budget_credits} Kredi</span>
                </div>
                <div>
                  <span class="opacity-40 block text-[9px] uppercase">Görev Sahibi</span>
                  <span class="font-bold text-white">{@selected_task.created_by}</span>
                </div>
                <div>
                  <span class="opacity-40 block text-[9px] uppercase">Ajan Durumu</span>
                  <span class="font-bold text-white uppercase flex items-center gap-1.5">
                    <%= case @selected_task.status do %>
                      <% "escrowed" -> %>
                        <span class="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"></span>
                        <span class="text-blue-400">Todo</span>
                      <% "working" -> %>
                        <span class="w-1.5 h-1.5 rounded-full bg-amber-500 animate-ping"></span>
                        <span class="text-amber-500">Working</span>
                      <% "artifact_submitted" -> %>
                        <span class="w-1.5 h-1.5 rounded-full bg-secondary"></span>
                        <span class="text-secondary">Review</span>
                      <% "completed" -> %>
                        <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
                        <span class="text-success">Done</span>
                      <% _ -> %>
                        <span class="w-1.5 h-1.5 rounded-full bg-neutral-500"></span>
                        <span class="opacity-50">{@selected_task.status}</span>
                    <% end %>
                  </span>
                </div>
              </div>
              <div class="pt-2 text-xs border-t border-white/5">
                <span class="opacity-40 block text-[9px] uppercase mb-1">Talimatlar</span>
                <p class="text-white/80 leading-relaxed bg-neutral-950 p-2.5 rounded-xl border border-white/5">
                  {@selected_task.instructions}
                </p>
              </div>
            </div>

            <%!-- Assignee Agent details --%>
            <%= if @selected_task.agent do %>
              <div class="p-4 rounded-2xl bg-neutral-900 border border-white/5 flex items-center justify-between gap-4">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-primary to-secondary flex items-center justify-center text-white font-black shadow-lg">
                    {String.at(@selected_task.agent.name, 0)}
                  </div>
                  <div>
                    <h4 class="text-xs font-black text-white">{@selected_task.agent.name}</h4>
                    <span class="text-[9px] opacity-40 uppercase tracking-wider block">
                      {@selected_task.agent.role}
                    </span>
                  </div>
                </div>
                <div class="text-right">
                  <span class="badge badge-sm badge-primary font-black uppercase text-[9px] mb-1">
                    Seviye {@selected_task.agent.level}
                  </span>
                  <div class="text-[9px] opacity-50">{@selected_task.agent.xp} XP</div>
                  <div class="w-20 bg-neutral-950 rounded-full h-1 mt-1 overflow-hidden border border-white/5">
                    <div
                      class="bg-primary h-full"
                      style={"width: #{rem(@selected_task.agent.xp, 100)}%;"}
                    >
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%!-- Simulation Console Terminal logs --%>
            <div class="flex flex-col bg-neutral-950 border border-white/10 rounded-2xl overflow-hidden font-mono shadow-inner">
              <header class="bg-neutral-900/60 px-4 py-2 border-b border-white/5 flex items-center justify-between">
                <div class="flex items-center gap-1.5">
                  <span class="w-2.5 h-2.5 rounded-full bg-red-500/70"></span>
                  <span class="w-2.5 h-2.5 rounded-full bg-yellow-500/70"></span>
                  <span class="w-2.5 h-2.5 rounded-full bg-green-500/70"></span>
                </div>
                <span class="text-[9px] text-white/40 tracking-wider">CONSOLE_SHELL ~ bash</span>
              </header>
              <div class="p-4 h-64 overflow-y-auto text-[10px] space-y-2 select-text text-green-400">
                <%= for log <- @console_logs do %>
                  <div class="leading-relaxed">
                    <span class="text-white/30 mr-1.5">$</span>
                    <%= if String.contains?(log, "[SYSTEM]") do %>
                      <span class="text-blue-400">{log}</span>
                    <% else %>
                      <%= if String.contains?(log, "[ERROR]") do %>
                        <span class="text-red-500 font-bold">{log}</span>
                      <% else %>
                        <span>{log}</span>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
                <%= if @selected_task.status == "working" do %>
                  <div class="flex items-center gap-1">
                    <span class="text-white/30">$</span>
                    <span class="w-1.5 h-3 bg-green-400 animate-pulse inline-block"></span>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Review deliverable box --%>
            <%= if @selected_task.status in ["artifact_submitted", "completed"] do %>
              <div class="p-4 rounded-2xl bg-neutral-900 border border-white/5 space-y-3 animate-fade-in">
                <div class="flex items-center justify-between">
                  <h3 class="text-xs font-black text-white uppercase tracking-wider">
                    📦 Teslim Edilen Rapor
                  </h3>
                  <span class="text-[9px] font-bold text-secondary uppercase">
                    Artifact Submitted
                  </span>
                </div>
                <div class="text-[10px] text-white/70 bg-neutral-950 p-4 rounded-xl border border-white/5 max-h-60 overflow-y-auto font-sans select-text">
                  <div class="prose prose-sm prose-invert prose-xs">
                    <%= if @selected_task.metadata["output"] do %>
                      <p class="whitespace-pre-wrap">{@selected_task.metadata["output"]}</p>
                    <% else %>
                      <p class="italic opacity-50">
                        Görev raporu başarıyla sisteme aktarıldı. (Lokal dosya yolu: {@selected_task.artifact_url})
                      </p>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Console Footer controls --%>
          <footer class="p-6 bg-neutral-950 border-t border-white/5 space-y-4">
            <%= case @selected_task.status do %>
              <% status when status in ["escrowed", "accepted", "draft"] -> %>
                <button
                  phx-click="launch_agent"
                  phx-value-id={@selected_task.id}
                  class="w-full btn btn-primary bg-gradient-to-r from-primary to-secondary hover:opacity-90 border-0 text-white font-black tracking-wide rounded-2xl flex items-center justify-center gap-2"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    class="w-4 h-4"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15.59 14.37a6 6 0 0 1-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 0 0 6.16-12.12A14.98 14.98 0 0 0 9.59 2.5 14.98 14.98 0 0 0 3.43 14.62a14.97 14.97 0 0 0 6.16 12.12m5.84-2.58a14.98 14.98 0 0 0 1.94-1.89m-1.94 1.89A14.98 14.98 0 0 1 9.59 21.5v-4.8"
                    />
                  </svg>
                  Ajanı Çalıştır (Launch Agent)
                </button>
              <% "working" -> %>
                <div class="flex items-center justify-center gap-3 p-4 bg-amber-500/10 border border-amber-500/20 text-amber-500 rounded-2xl">
                  <span class="w-2.5 h-2.5 rounded-full bg-amber-500 animate-ping"></span>
                  <span class="text-xs font-bold uppercase tracking-wider">
                    Ajan Otonom Görevi İcra Ediyor...
                  </span>
                </div>
              <% "artifact_submitted" -> %>
                <div class="flex flex-col gap-2">
                  <button
                    phx-click="approve_task"
                    phx-value-id={@selected_task.id}
                    class="w-full btn btn-success text-white font-black tracking-wide rounded-2xl flex items-center justify-center gap-2"
                  >
                    ✓ Onayla & Öde (Approve Release)
                  </button>
                  <button
                    phx-click="cancel_task"
                    phx-value-id={@selected_task.id}
                    class="w-full btn btn-outline btn-error font-bold tracking-wide rounded-2xl"
                  >
                    ✕ Görevi İptal Et (Refund Escrow)
                  </button>
                </div>
              <% "completed" -> %>
                <div class="p-4 bg-success/10 border border-success/20 text-success text-center rounded-2xl text-xs font-black uppercase tracking-wider flex items-center justify-center gap-2">
                  🏆 GÖREV ONAYLANDI & TAMAMLANDI
                </div>
              <% "refunded" -> %>
                <div class="p-4 bg-red-500/10 border border-red-500/20 text-red-400 text-center rounded-2xl text-xs font-bold uppercase tracking-wider">
                  ✕ GÖREV İPTAL EDİLDİ (İADE EDİLDİ)
                </div>
              <% _ -> %>
                <div class="p-4 bg-neutral-900 border border-white/5 text-center text-xs opacity-50 rounded-2xl">
                  GÖREV KAPATILDI
                </div>
            <% end %>
          </footer>
        </div>
      <% end %>
    </div>
    """
  end
end
