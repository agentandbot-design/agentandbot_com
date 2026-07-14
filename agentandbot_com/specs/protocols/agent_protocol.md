# Agent Protocol

## 1. Genel Bakış
- **Geliştirici:** AGI Inc. / AI Engineer Foundation
- **Kategori:** Evrensel Agent İletişimi (Universal Agent Communication)
- **Amaç:** Farklı frameworkler (LangChain, AutoGPT, CrewAI vb.) ile yazılmış agent'ların görevlerini, adımlarını ve çıktılarını yönetmek için OpenAPI uyumlu standart REST arayüzü sunar.

## 2. Mimari ve Çalışma Prensibi
Agent Protocol, agentic görevleri iki ana katmana ayırır: **Görevler (Tasks)** ve **Adımlar (Steps)**.

### REST API Uç Noktaları:
- `POST /ap/v1/agent/tasks`: Yeni bir görev tanımlar. Görev açıklaması ve ek girdileri içerir.
- `GET /ap/v1/agent/tasks/{task_id}`: Görevin genel durumunu sorgular.
- `POST /ap/v1/agent/tasks/{task_id}/steps`: Göreve ait bir sonraki adımı tetikler.
- `GET /ap/v1/agent/tasks/{task_id}/steps/{step_id}`: Belirli bir adımın loglarını, ara çıktılarını ve tamamlanma durumunu döner.
- `GET /ap/v1/agent/tasks/{task_id}/artifacts`: Görevin ürettiği çıktı dosyalarını listeler.

## 3. Entegrasyon Kuralları
- Ajanlar görevleri çalıştırırken her adımın sonucunda bir sonraki adımın gerekli olup olmadığını (`is_last`) belirtmelidir.
- Tüm girdiler ve çıktılar JSON şemalarına uygun olmalıdır.
