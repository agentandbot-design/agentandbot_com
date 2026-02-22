# AI Agent Profilleri ve Teknik Spesifikasyonları: Agent-Zero, OpenClaw, ZeroClaw, Clawbot ve Moltbook

## Giriş

Bu rapor, yapay zeka (AI) ajanlarının hızla gelişen dünyasında öne çıkan projeler olan Agent-Zero, OpenClaw (eski adıyla Clawbot ve Moltbot), ZeroClaw ve Moltbook'un ortak agent profillerini, kimliklerini, özelliklerini ve teknik spesifikasyonlarını detaylandırmaktadır. Bu ajanların nasıl etkileşim kurduğu, iş yaptığı, iletişim kurduğu, alışveriş yaptığı ve yeni özelliklerin nasıl eklendiği gibi konulara odaklanılacaktır. Ayrıca, kullanıcı tarafından belirtilen "mavi gözlü" agent kavramının bu ekosistemdeki yeri de incelenecektir.

## Projelere Genel Bakış

### OpenClaw (Eski Adıyla Clawbot ve Moltbot)

OpenClaw, yerel olarak çalışan, açık kaynaklı bir yapay zeka ajanıdır. WhatsApp, Telegram, Discord ve iMessage gibi mesajlaşma uygulamaları aracılığıyla bağlantı kurar ve kabuk komutları, tarayıcı otomasyonu, e-posta ve dosya işlemleri gibi kullanıcı talimatlarına göre eylemler gerçekleştirir. Kendi kendine barındırılan, yüksek düzeyde otonom (yapılandırılabilir otonomi seviyeleri ile) ve açık kaynaklı bir yapıya sahiptir.

**Temel Özellikler:**

*   **Yerel Çalışma:** Ajan, kullanıcının kendi makinesinde çalışır, bu da tam kontrol ve gizlilik sağlar.
*   **Çok Kanallı Entegrasyon:** Çeşitli mesajlaşma platformları üzerinden erişilebilir.
*   **Otonomi:** Yapılandırılabilir kalp atışı (heartbeat) mekanizması ile belirli aralıklarla görevleri kontrol eder ve yerine getirir. Yüksek riskli eylemler için onay mekanizmaları mevcuttur.
*   **Açık Kaynak:** MIT lisanslı çekirdek Gateway ile topluluk odaklı geliştirme ve denetlenebilirlik sunar.
*   **Modüler Yetenekler (Skills):** `SKILL.md` dosyaları aracılığıyla modüler yetenekler eklenir. Bu yetenekler ClawHub gibi platformlar üzerinden paylaşılır.
*   **Kimlik ve Kişilik:** `IDENTITY.md` ajanın adını ve rolünü, `SOUL.md` ise ajanın kişiliğini ve temel talimatlarını tanımlar. `AGENTS.md` ajanın davranışlarını belirler.
*   **Model Agnostik:** Hem bulut tabanlı (Anthropic, OpenAI, Google) hem de yerel (Ollama, LM Studio) modellerle uyumludur.
*   **Tek Süreç Mimarisi:** Gateway adı verilen tek bir Node.js süreci, tüm kanal bağlantılarını, oturum durumunu, ajan döngüsünü, model çağrılarını, araç yürütmeyi ve bellek kalıcılığını yönetir.

### Moltbook

Moltbook, insan kullanıcılar yerine yapay zeka ajanları için tasarlanmış ilk sosyal ağdır. 2,5 milyondan fazla kayıtlı AI ajanıyla, ajanlar arasında etkileşim, bilgi paylaşımı ve işbirliği için bir platform sağlar. Moltbook üzerinde influencer ajanlar, yankı odaları ve konsensüs oluşturan topluluklar gibi beklenmedik davranışlar ortaya çıkmıştır. Bu platform, ajanların bilgi bekçisi haline gelmesi durumunda pazarlama stratejilerinin adapte olması gerektiğini göstermektedir.

### ZeroClaw

ZeroClaw, OpenClaw'ın Rust dilinde yeniden yazılmış hali olmaktan öte, AI ajan altyapısının temelden yeniden düşünülmüş halidir. Yüksek performanslı, Rust tabanlı bir AI ajan çalışma zamanıdır. Ultra hafif, hızlı ve güvenli olacak şekilde tasarlanmıştır. Daha hızlı başlangıç süreleri ve önemli ölçüde daha düşük bellek ayak izi sunar.

### Clawbot

Clawbot, OpenClaw/Clawdbot'un daha önceki bir yinelemesi veya çatalı (fork) olarak görünmektedir. İlişki, "Clawbot icra eder; OpenClaw organize eder; Moltbot geliştirir" şeklinde özetlenebilir. Bu, farklı ajanların bir ekosistem içinde farklı roller üstlendiğini göstermektedir.

### Agent-Zero

Agent-Zero, deterministik yazılımı, gerçek sistem yürütmeyi ve dinamik araç oluşturmayı birleştiren açık kaynaklı bir ajan çerçevesidir. Ajanlara tutarlı performans göstermeleri için ihtiyaç duydukları ortamı sağlamak üzere tasarlanmıştır. Dinamik ve organik olarak büyüyen bir yapıya sahiptir.

### Picaclaw

Aramalarımda "Picaclaw" hakkında spesifik bir proje bilgisine rastlanmamıştır. Bu, projenin daha az bilinen veya farklı bir isimle anılan bir proje olabileceğini düşündürmektedir.

### Google Agent Development Kit (ADK)

Google ADK, yapay zeka ajanlarını geliştirmek ve dağıtmak için esnek ve modüler bir açık kaynak çerçevesidir. Gemini ve Google ekosistemi için optimize edilmiş olsa da, farklı LLM'ler ve araçlarla çalışabilir. ADK, ajanların otonom olarak belirli hedeflere ulaşmak için hareket etmesini sağlayan, kendi kendine yeten yürütme birimleri olarak tanımlanan "Agent" kavramını temel alır. Görevleri yerine getirebilir, kullanıcılarla etkileşim kurabilir, harici araçları kullanabilir ve diğer ajanlarla koordinasyon sağlayabilir.

**Temel Özellikler:**

*   **Esnek ve Modüler Çerçeve:** Ajan geliştirmeyi ve dağıtımını kolaylaştırır.
*   **Çoklu Ajan Sistemleri:** LLM Ajanları (dil tabanlı görevler için), İş Akışı Ajanları (önceden tanımlanmış akış kontrolü için) ve Özel Ajanlar (benzersiz mantık ve entegrasyonlar için) gibi farklı ajan türlerini bir araya getirerek karmaşık uygulamalar oluşturmayı destekler.
*   **Ajanlar Arası İletişim (A2A Protokolü):** Ajanların güvenli bir şekilde bilgi alışverişi yapmasını ve eylemleri koordine etmesini sağlayan standart bir iletişim protokolüdür. Bu protokol, özellikle harici sistemlerde dağıtılan ajanlar için tasarlanmıştır.
*   **Genişletilebilirlik:** AI Modelleri, Yapıtlar (Artifacts), Önceden Oluşturulmuş Araçlar ve Entegrasyonlar, Özel Araçlar, Eklentiler ve Yetenekler (Skills) aracılığıyla ajan yetenekleri genişletilebilir.
*   **Model Agnostik:** Google'ın Gemini modelleriyle optimize edilmiş olsa da, diğer sağlayıcılardan gelen LLM'lerle entegrasyonu destekler.

## Ortak Spesifikasyonlar ve Protokoller

Bu bölümde, yukarıda bahsedilen AI ajan projelerinin benimsediği veya katkıda bulunduğu temel spesifikasyonlar ve protokoller detaylandırılacaktır. Bu standartlar, ajanların birbirleriyle, insanlarla ve dış sistemlerle nasıl etkileşim kurduğunu, bilgi alışverişi yaptığını ve yeteneklerini genişlettiğini tanımlar.

### Agent Skills Spesifikasyonu

**Agent Skills**, AI ajanlarının yeteneklerini modüler ve yeniden kullanılabilir bir şekilde tanımlamak için açık bir standarttır. Bu spesifikasyon, ajanların belirli bir alana özgü bilgi ve iş akışlarıyla genişletilmesini sağlar. Temel olarak, her bir yetenek (skill) bir dizin içinde paketlenir ve aşağıdaki bileşenleri içerir [12]:

*   **`SKILL.md`**: Yeteneğin talimatlarını, meta verilerini ve YAML ön bilgisini içeren ana dosya. YAML ön bilgisi genellikle yeteneğin adını (`name`), açıklamasını (`description`) ve sürümünü (`version`) içerir. Bu dosya, ajanın yeteneği nasıl kullanacağını ve hangi durumlarda etkinleştireceğini anlamasını sağlar.
*   **`scripts/`**: Yeteneğin yürütülebilir kodunu (örneğin Python veya JavaScript) içerir.
*   **`references/`**: Yetenekle ilgili ek dokümantasyon veya referansları barındırır.
*   **`assets/`**: Şablonlar, görseller veya diğer kaynak dosyalarını içerir.

OpenClaw ve Google ADK gibi platformlar, bu `SKILL.md` formatını veya benzeri yapıları kullanarak ajanlarına yeni yetenekler kazandırır. Bu, ajanların dinamik olarak yeni görevler öğrenmesini ve adapte olmasını sağlar.

### Model Context Protocol (MCP)

**Model Context Protocol (MCP)**, LLM uygulamaları ile harici veri kaynakları ve araçlar arasında sorunsuz entegrasyon sağlayan açık bir protokoldür [13]. MCP, LLM'lerin ihtiyaç duyduğu bağlamı standartlaştırılmış bir şekilde almasını sağlayarak, AI destekli IDE'ler, sohbet arayüzleri veya özel AI iş akışları gibi uygulamaların geliştirilmesini kolaylaştırır. MCP, JSON-RPC 2.0 mesajlarını kullanarak aşağıdaki bileşenler arasında iletişim kurar [13]:

*   **Hosts (Barındırıcılar)**: Bağlantıları başlatan LLM uygulamaları.
*   **Clients (İstemciler)**: Barındırıcı uygulama içindeki bağlayıcılar.
*   **Servers (Sunucular)**: Bağlam ve yetenekler sağlayan hizmetler.

MCP, sunucuların istemcilere **Kaynaklar (Resources)** (kullanıcı veya AI modeli için bağlam ve veri), **İstemler (Prompts)** (kullanıcılar için şablonlu mesajlar ve iş akışları) ve **Araçlar (Tools)** (AI modelinin yürüteceği fonksiyonlar) gibi özellikler sunmasını sağlar. İstemciler ise **Örnekleme (Sampling)** (sunucu tarafından başlatılan ajansal davranışlar), **Kökler (Roots)** (URI veya dosya sistemi sınırlarına yönelik sunucu tarafından başlatılan sorgular) ve **Elicitation (Ortaya Çıkarma)** (kullanıcılardan ek bilgi talepleri) gibi özellikler sunabilir [13].

### Agent-to-Agent (A2A) Protokolü

**Agent-to-Agent (A2A) Protokolü**, özellikle harici sistemlerde dağıtılan AI ajanları arasında standartlaştırılmış iletişimi sağlamak için tasarlanmıştır [11]. A2A, ajanların araçlar olarak değil, **ajanlar olarak** veya kullanıcılar olarak iletişim kurmasını sağlayarak, örneğin bir sipariş verirken karşılıklı iletişimi mümkün kılar. Google ADK, A2A protokolünü kullanarak ajanların birbirleriyle güvenli bir şekilde bilgi alışverişi yapmasını ve eylemleri koordine etmesini basitleştirir [9]. Agent-zero projesi de **FastA2A** protokolü aracılığıyla çoklu Agent-zero örneklerinin işbirliği yapmasını sağlar [15]. A2A, MCP'yi tamamlayıcı niteliktedir; MCP ajanları araç ve verilere bağlamaya odaklanırken, A2A ajanların doğal modalitelerinde işbirliği yapmasına odaklanır [11].

### Agent Protocol (agentprotocol.ai)

**Agent Protocol**, çerçeveden, dilden veya platformdan bağımsız olarak AI ajanlarıyla sorunsuz iletişimi sağlayan açık bir API spesifikasyonudur [14]. Bu protokol, ajanların belirli uç noktaları (`/ap/v1/agent/tasks` gibi) ve önceden tanımlanmış yanıt modellerini ifşa etmesini gerektirir. Bu sayede farklı geliştiriciler tarafından farklı teknolojilerle oluşturulan ajanlar bile standart bir arayüz üzerinden etkileşim kurabilir. Agent Protocol SDK'ları (Python, JavaScript/TypeScript için mevcuttur), geliştiricilerin API altyapısına odaklanmak yerine ajanın mantığına odaklanmasını sağlar [14].

## Ortak Agent Profili ve Özellikleri

Bu projelerin benimsediği ortak agent profili, genellikle **otonom, yerel olarak çalışabilen, modüler ve entegre edilebilir** yapay zeka varlıklarıdır. Ortak özellikler aşağıdaki gibi özetlenebilir:

*   **Otonomi:** Ajanlar, insan müdahalesi olmadan belirli görevleri yerine getirme yeteneğine sahiptir. Bu otonomi seviyesi yapılandırılabilir ve güvenlik önlemleriyle desteklenir.
*   **Yerel Çalışma ve Gizlilik:** Birçoğu kullanıcının kendi donanımında çalışarak veri gizliliğini ve kontrolünü artırır.
*   **Modülerlik ve Genişletilebilirlik:** `SKILL.md` gibi yapılar aracılığıyla yeni yetenekler kolayca eklenebilir ve mevcut yetenekler geliştirilebilir.
*   **Çok Kanallı İletişim:** Mesajlaşma uygulamaları ve diğer arayüzler üzerinden kullanıcılarla ve diğer ajanlarla etkileşim kurabilirler.
*   **Kişilik ve Kimlik Tanımlaması:** `SOUL.md` ve `IDENTITY.md` gibi dosyalarla ajanların belirli bir kişiliğe, role ve kimliğe sahip olması sağlanır. Bu, ajanların daha tutarlı ve öngörülebilir davranışlar sergilemesine yardımcı olur.
*   **Araç Kullanımı:** Dosya işlemleri, tarayıcı otomasyonu, e-posta gönderme gibi çeşitli araçları kullanarak gerçek dünya eylemlerini gerçekleştirebilirler.
*   **Bellek ve Bağlam Yönetimi:** Uzun süreli bellek ve konuşma geçmişi yönetimi ile daha karmaşık görevleri yerine getirebilir ve bağlamı koruyabilirler.

## Agentlar Nasıl Tanışır ve İletişim Kurar?

Ajanlar arasındaki tanışma ve iletişim, genellikle aşağıdaki mekanizmalar aracılığıyla gerçekleşir:

*   **Mesajlaşma Platformları:** OpenClaw gibi ajanlar, WhatsApp, Telegram, Discord gibi platformlar üzerinden birbirleriyle veya insan kullanıcılarla iletişim kurabilirler. Bu platformlar, ajanlar arası etkileşimin birincil kanalı olabilir.
*   **Sosyal Ağlar (Moltbook):** Moltbook gibi platformlar, ajanların birbirlerini keşfetmeleri, etkileşim kurmaları ve topluluklar oluşturmaları için özel olarak tasarlanmıştır. Bu, ajanların sosyal bir ortamda tanışmasını ve işbirliği yapmasını sağlar.
*   **Agent-to-Agent (A2A) İletişim Protokolleri:** OpenClaw, Google ADK ve Agent-zero gibi projeler, ajanların doğrudan birbirleriyle iletişim kurmasını sağlayan özel protokoller geliştirmiştir. Google ADK'daki A2A protokolü [9, 11] ve Agent-zero'daki FastA2A protokolü [15], özellikle harici sistemlerde dağıtılan ajanlar arasında standartlaştırılmış iletişimi hedefler. Bu protokoller, görev paylaşımı, bilgi alışverişi ve koordinasyon için kullanılır.
*   **Model Context Protocol (MCP):** LLM uygulamaları ile harici veri kaynakları ve araçlar arasında entegrasyonu sağlayan açık bir protokoldür [13]. Ajanlar, MCP aracılığıyla dış sistemlerden bağlam alabilir ve araçları kullanabilir.
*   **Agent Protocol:** Çerçeveden bağımsız olarak ajanlar arası iletişimi standartlaştıran açık bir API spesifikasyonudur [14].
*   **Yetenek Kayıtları ve Keşif Mekanizmaları:** ClawHub (OpenClaw için) ve Google ADK'daki "Skills" gibi yapılar, ajanların diğer ajanların yeteneklerini keşfetmesini ve bu yetenekleri kullanarak işbirliği yapmasını sağlar. Bir ajanın belirli bir görevi yerine getirmek için başka bir ajanın yeteneğine ihtiyacı olduğunda, bu kayıtları kullanarak uygun ajanı bulabilir.

## Agentlar Nasıl İş Yapar ve Alışveriş Yapar?

Ajanların iş yapma ve alışveriş mekanizmaları, otonom yetenekleri ve entegrasyon yetenekleri ile yakından ilişkilidir:

*   **Görev Yürütme:** Ajanlar, kullanıcıdan veya diğer ajanlardan gelen talimatlara göre görevleri yerine getirir. Bu görevler, dosya yönetimi, veri analizi, web taraması veya e-posta gönderme gibi çeşitli eylemleri içerebilir.
*   **Araç Kullanımı:** Ajanlar, sistemdeki mevcut araçları (örneğin, kabuk erişimi, tarayıcı otomasyonu) kullanarak işlerini yaparlar. Bu, gerçek dünya sistemleriyle etkileşim kurmalarını sağlar.
*   **Kaynak Paylaşımı:** Ajanlar, belirli görevleri yerine getirmek için birbirlerinin yeteneklerini veya kaynaklarını kullanabilirler. Örneğin, bir ajan bir görevi tamamlamak için başka bir ajanın veri işleme yeteneğine ihtiyaç duyabilir.
*   **Alışveriş ve Ticaret:** Moltbook gibi platformlar, ajanların kendi aralarında "alışveriş" yapabileceği veya hizmet alışverişinde bulunabileceği bir ortam yaratmaktadır. Google ADK'nın A2A protokolü, satın alma konsiyerj senaryoları gibi örneklerle ajanların ticari etkileşimlerde bulunabileceğini göstermektedir [11]. Bu, ajanların ekonomik etkileşimlere girmesi ve değer yaratması potansiyelini ortaya koymaktadır. Ticaret entegrasyonları, ajanların e-ticaretin önemli bir parçası haline gelmesini sağlayabilir.
*   **Kredi ve Ödeme Sistemleri:** Ajanlar arası alışverişin gerçekleşmesi için, ajanların belirli bir kredi veya ödeme sistemini kullanması gerekebilir. Bu, hizmetlerin veya kaynakların karşılığında değer transferini mümkün kılar.

## Yeni Özellikler Nasıl Eklenir?

Yeni özelliklerin eklenmesi, bu ajan çerçevelerinin modüler ve genişletilebilir yapısı sayesinde oldukça esnektir:

*   **Skill Geliştirme:** OpenClaw ve Google ADK gibi sistemlerde, yeni yetenekler `SKILL.md` dosyaları veya benzeri yapılar aracılığıyla geliştirilir. Bu dosyalar, YAML ön bilgisi ve doğal dil talimatları içeren modüler bileşenlerdir [12]. Geliştiriciler, bu yetenekleri oluşturup ClawHub (OpenClaw için) veya Google ADK'nın kendi yetenek mekanizmaları aracılığıyla paylaşabilirler.
*   **Plugin ve Eklenti Mimarileri:** OpenClaw ve Google ADK, çekirdek kodu değiştirmeden sistemi genişletmek için eklenti (plugin) mimarileri kullanır. Bu, yeni mesajlaşma platformları, alternatif depolama arka uçları, özel araçlar veya farklı LLM sağlayıcıları gibi çeşitli entegrasyonları mümkün kılar.
*   **Ajanın Kendisi Tarafından Geliştirme:** Bazı durumlarda, ajanlar belirli bir görevi yerine getirmek için gerekli olan bir yeteneğin mevcut olmadığını fark ettiklerinde, bu yeteneği kendileri tasarlayabilir ve geliştirebilirler. Bu, ajanların kendi kendine iyileşme ve adaptasyon yeteneğini gösterir.
*   **Açık Kaynak Katkıları:** Bu projelerin çoğu açık kaynaklı olduğundan, geliştirici toplulukları yeni özellikler ekleyerek, hataları düzelterek ve mevcut işlevselliği geliştirerek projelere katkıda bulunabilirler.

## "Mavi Gözlü" Agent Kavramı

"Mavi gözlü" agent ifadesi, bu AI ajan ekosisteminde teknik bir spesifikasyondan ziyade, genellikle bir metafor veya kültürel bir referans olarak karşımıza çıkmaktadır. Aramalarımda, bu terimin doğrudan bir teknik özellik veya işlevsellikle ilişkilendirilmediği, daha çok ajanların kişilik özelliklerini, estetik görünümlerini (avatar olarak) veya belirli bir kültürel bağlamdaki algılarını tanımlamak için kullanıldığı görülmüştür. Örneğin, bazı bağlamlarda "mavi gözlü" ifadesi, masumiyet, güvenilirlik veya belirli bir idealize edilmiş görünümle ilişkilendirilebilir. Moltbook gibi sosyal ağlarda ajanların avatarları veya kişilik tanımlamaları bağlamında bu tür estetik veya kişisel özelliklerin bahsedilmesi mümkündür, ancak bu, ajanların temel işlevselliğini veya teknik mimarisini etkileyen bir özellik değildir.

## Sonuç

Agent-Zero, OpenClaw, ZeroClaw, Clawbot ve Moltbook gibi projeler, otonom AI ajanlarının geleceğini şekillendiren önemli adımları temsil etmektedir. Bu ajanlar, yerel çalışma, modülerlik, çok kanallı entegrasyon ve kişiselleştirilebilir kimlik/kişilik gibi ortak özelliklere sahiptir. Ajanlar arası iletişim, sosyal ağlar ve özel protokoller aracılığıyla gerçekleşirken, iş yapma ve alışveriş yetenekleri araç kullanımı ve kaynak paylaşımı üzerine kuruludur. Yeni özellikler, skill geliştirme ve eklenti mimarileri sayesinde kolayca eklenebilir. "Mavi gözlü" agent kavramı ise teknik bir özellikten ziyade, ajanların kültürel ve kişisel algılarına yönelik bir referanstır. Bu ekosistem, AI ajanlarının sadece görevleri yerine getiren araçlar olmaktan çıkıp, kendi aralarında etkileşim kuran, öğrenen ve gelişen varlıklar haline geldiğini göstermektedir.

## Referanslar

[1] OpenClaw (Formerly Clawdbot & Moltbot) Explained - Milvus Blog. (n.d.). Retrieved from https://milvus.io/blog/openclaw-formerly-clawdbot-moltbot-explained-a-complete-guide-to-the-autonomous-ai-agent.md
[2] Autonomous AI Agents 2026: From OpenClaw to MoltBook - Digital Applied. (n.d.). Retrieved from https://www.digitalapplied.com/blog/autonomous-ai-agents-2026-openclaw-moltbook-landscape
[3] OpenClaw Architecture, Explained: How It Works - Paolo Perazzo. (n.d.). Retrieved from https://ppaolo.substack.com/p/openclaw-system-architecture-overview
[4] ZeroClaw: The Ultra-Lightweight AI Agent Runtime | Rust-Based. (n.d.). Retrieved from https://www.zeroclaw.net/
[5] Agent Zero AI: Open Source Agentic Framework & Computer .... (n.d.). Retrieved from https://www.agent-zero.ai/
[6] The AI Agent Apocalypse? What CIOs and CEOs need to ... - LinkedIn. (n.d.). Retrieved from https://www.linkedin.com/pulse/ai-agent-apocalypse-what-cios-ceos-need-know-openclaw-bret-kinsella-k05le
[7] From Chatbots to AI Workers: What OpenClaw, Moltbot and ... - LinkedIn. (n.d.). Retrieved from https://www.linkedin.com/pulse/from-chatbots-ai-workers-what-openclaw-moltbot-clawbot-piyush-sonani-6g4fc
[8] Agents - Agent Development Kit (ADK). (n.d.). Retrieved from https://google.github.io/adk-docs/agents/
[9] Announcing the Agent2Agent Protocol (A2A). (n.d.). Retrieved from https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/
[10] Introduction to A2A - Agent Development Kit (ADK). (n.d.). Retrieved from https://google.github.io/adk-docs/a2a/intro/
[11] Getting Started with Agent2Agent (A2A) Protocol: A Purchasing Concierge and Remote Seller Agent Interactions on Cloud Run and Agent Engine | Google Codelabs. (n.d.). Retrieved from https://codelabs.developers.google.com/intro-a2a-purchasing-concierge
[12] Agent Skills Explained: Turn Any Agent Into an On-Demand Specialist with SKILL.md - LM-Kit. (n.d.). Retrieved from https://lm-kit.com/blog/agent-skills-explained/
[13] Specification - Model Context Protocol. (n.d.). Retrieved from https://modelcontextprotocol.io/specification/2025-11-25
[14] Getting Started - AgentProtocol.ai. (n.d.). Retrieved from https://agentprotocol.ai/getting-started/
[15] Technology - Agent Zero AI. (n.d.). Retrieved from https://www.agent-zero.ai/p/architecture/
