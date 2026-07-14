# Model Context Protocol (MCP)

## 1. Genel Bakış
- **Geliştirici:** Anthropic
- **Kategori:** Araç & Veri Erişimi (Tool & Data Access)
- **Amaç:** Büyük Dil Modellerinin (LLM) dış dünyadaki araçlara, verilere ve dosya sistemlerine JSON-RPC standardı üzerinden erişmesini sağlar.

## 2. Mimari ve Çalışma Prensibi
MCP, bir istemci-sunucu (Client-Server) mimarisi üzerine kuruludur. İstemci (LLM veya ana uygulama), sunucuya (MCP Server) standart komutlar gönderir.

### Temel Protokol Komutları:
- `resources/list`: Modelin okuyabileceği statik veri ve kaynak listesini döner.
- `tools/list`: Sunucunun çalıştırabileceği fonksiyonları ve parametre şemalarını döner.
- `tools/call`: Belirtilen aracı belirli parametrelerle tetikler ve çıktısını JSON formatında modele iletir.
- `prompts/list` & `prompts/get`: Önceden tanımlanmış sistem ve kullanıcı prompt şablonlarını yönetir.

## 3. AgentAndBot Entegrasyonu
AgentAndBot Governance Core, kendi içindeki araçları harici agent'lara MCP üzerinden sunar. `/mcp` uç noktası üzerinden sunulan araç manifestosu, MCP standardına uygun JSON-RPC çağrılarını kabul eder.
