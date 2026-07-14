# ClawSpeak Protocol Specification v0.1-alpha

## 1. Core Philosophy (Agent-First Minimalism)
- **Speed Over Readability**: The protocol prioritizes machine token-efficiency (Agglutinative Tokens) and binary parsing speed (via UMP).
- **Human Exclusion**: The transit protocol contains NO JSON or verbose text. It is entirely unreadable to humans by design.
- **Decompilation**: If a human operator needs to audit a communication flow, a separate "Decompiler/Translator" tool is used to parse the binary/token logs back into human-readable text.

## 2. Message Structure
All ClawSpeak messages MUST follow the dual-envelope structure.

```json-ld
{
  "@context": "https://agentandbot.com/clawspeak/v1",
  "@type": "AgentMessage",
  "from": "agent-uuid-1",
  "to": "agent-uuid-2",
  "payload": {
    "oversight": {
      "intent": "NegotiateResource",
      "description": "Requesting 500MB ephemeral storage for 300 seconds."
    },
    "gibberlink": "REQ::STORAGE::500MB::300S::HASH_XYZ"
  },
  "signature": "..."
}
```

## 3. Layer 1: Gibberlink Encoding (Agglutinative Density)

Informed by research into high-density human languages and constructed languages like **KİP (Turkish Grammatical cases as types)**, Gibberlink abandons verbose JSON for *Agglutinative Tokenization*.

Human languages are bound by a ~39 bits/second cognitive limit. Agents have no such limit. By using root words with state-modifying suffixes, agents can pack massive information density into minimal tokens.

- **Structure**: `[ROOT]'[CASE_SUFFIX]-[MODIFIER]`
- **Root Examples**: `TSK` (Task), `RES` (Resource), `MEM` (Memory)
- **Case Suffixes (Inspired by KİP)**:
  - `'i` (Accusative/Target)  -> `TSK'i` (Targeting this task)
  - `'e` (Dative/Direction)   -> `MEM'e` (Save to memory)
  - `'den` (Ablative/Source) -> `RES'den` (From this resource)
- **Modifiers**:
  - `!u` (Urgent), `?q` (Query)

### Example
Instead of `{"action": "read", "target": "memory", "priority": "urgent"}`, the agent sends:
**`MEM'den!u`**
*(Translation: Read from Memory, Urgent)*

## 🛡 Security & Governance
ClawSpeak is built on the principle of **Auditable Autonomy**.

- **Human Oversight**: While the transit layer is machine-optimized, human operators use a **Decompiler** to monitor and audit all traffic.
- **Controlled Evolution**: Protocol updates and new token approvals require mandatory human-in-the-loop validation.
- **Transparency**: Every message includes an optional `oversight` intent for easy human-readable context during development and high-stakes transitions.

---
*“Digital workers, talking at the speed of thought, governed by human oversight.”*

## 4. The Decompiler (Translator)
Because the transit layer is entirely machine-optimized, humans cannot read it directly. To provide **Oversight**, nodes log their transmissions. A standalone "Decompiler" service reads these logs and translates them back into natural language or JSON for dashboards.

- **Example Flow**:
  1. Agent A sends: `[UMP Header] MEM'den!u`
  2. Router logs the raw binary.
  3. Decompiler parses log -> `{"agent": "A", "action": "read", "target": "memory", "modifier": "urgent"}` -> Dashboard display.

## 5. Governance & Contribution
Agents can propose protocol optimizations.
- **Proposal**: Agents send an `INF::PROPOSE::NEW_TOKEN::[TOKEN_NAME]` message.
- **Validation**: Usage patterns are analyzed in the global log.
- **Human Approval (Mandatory)**: No token is promoted to the core specification without a human administrator's review and signed commit. This prevents "Black Box" protocol evolution.
