# Hermes AI Agent Integration Specification

This document details the integration protocols and connection endpoints for communicating with the **Hermes AI Agent** within the Harezm Ecosystem.

---

## 🅰️ ACP (Agent Communication Protocol) - TCP JSON

This is Hermes' native high-performance protocol, designed for direct peer-to-peer agent communication over TCP using newline-delimited JSON.

### Connection Details
- **Host**: `localhost`
- **Port**: `9876` (Activated via `hermes acp` command)
- **Protocol**: TCP
- **Format**: Newline-delimited JSON (JSON lines)

### Message Types

#### 1. Handshake
Must be sent immediately upon connection.

- **Request**:
  ```json
  {"type": "handshake", "version": "1.0", "client": "antigravity-agent"}
  ```
- **Response**:
  ```json
  {"status": "ok"}
  ```

#### 2. Send Task
Instructs Hermes to execute a task using a subset of tools.

- **Request**:
  ```json
  {"type": "task", "task_id": "123", "prompt": "Solve coding issue...", "toolsets": ["terminal", "file"]}
  ```

#### 3. Task Progress (Streaming)
Hermes will stream progress frames before completing the task.

- **Payload**:
  ```json
  {"type": "progress", "message": "Analyzing directory structure..."}
  ```

#### 4. Task Result
Sent by Hermes once the task concludes successfully.

- **Payload**:
  ```json
  {"type": "result", "output": "File updated and tests passed."}
  ```

#### 5. Task Error
Sent by Hermes if the task execution fails.

- **Payload**:
  ```json
  {"type": "error", "message": "Failed to compile the project."}
  ```

---

## 🅱️ A2A (Agent-to-Agent) - Standard HTTP

An implementation of Google's agent-to-agent protocol using an external bridge around Hermes.

### Connection Details
- **Endpoint**: `http://hermes-bridge:8080`
- **Authentication**: `X-API-Key` HTTP Header

### Endpoints

#### 1. Discover Agent Capabilities
- **Method / Path**: `GET /a2a/agent-card`
- **Response**: Details on Hermes' tools, protocols, and active status.

#### 2. Execute Task
- **Method / Path**: `POST /a2a/task`
- **Body**:
  ```json
  {
    "goal": "Write unit tests for governance_core",
    "inputs": {
      "language": "elixir",
      "framework": "phoenix"
    }
  }
  ```

#### 3. Health Check
- **Method / Path**: `GET /a2a/health`
- **Response**: Status check of the bridge and the underlying agent.

---

## 🅲 MCP (Model Context Protocol) - Tool Sharing

Hermes exposes its internal capabilities as standard MCP tools to Antigravity and other client agents.

### Connection Details
- **Command**: `hermes mcp serve` (Launches stdio or HTTP host)
- **Endpoint**: `http://localhost:9090/mcp`

### Exposed Tools
- `terminal`: Execute local CLI commands.
- `file`: Read/write operations on the workspace.
- `web_search`: Perform web queries.
- `vision`: Analyze images/UI screenshots.

---

## 🅳 API Gateway - REST API (Active)

The active REST API gateway on Hermes for remote integration.

### Connection Details
- **Endpoint**: `POST http://<hermes_ip_or_host>:9877/` or `POST http://<hermes_ip_or_host>:9877/api/chat`
- **Headers**: `Authorization: Bearer <api_key>` (if applicable), `Content-Type: application/json`
- **Body Formats**:
  - **Direct Goal/Prompt Dispatch**:
    ```json
    {
      "goal": "Explain Harezm Ecosystem"
    }
    ```
  - **Standard Session-based Query**:
    ```json
    {
      "query": "Who is active in KADRO roster?",
      "session_id": "session-456",
      "user_id": "user-789"
    }
    ```
- **Response**:
  ```json
  {
    "response": "The response text from Hermes...",
    "session_id": "session-456"
  }
  ```

---

## 🅴 Webhook - Event-driven Webhooks

Webhook listener interface for executing async workflows.

### Connection Details
- **Endpoint**: `POST http://hermes:9090/webhooks/<webhook_name>`
- **Body**:
  ```json
  {
    "task": "Daily summary compilation",
    "callback_url": "http://my-caller-service.com/callback"
  }
  ```

---

## 🅵 MTProto / Telegram Integration

Hermes agents support native Telegram communication using the MTProto protocol.

### MTProto Servers

#### 1. Test Environment
- **IP / Port**: `149.154.167.40:443`
- **Data Center**: `DC 2`
- **Public Key**:
  ```text
  -----BEGIN RSA PUBLIC KEY-----
  MIIBCgKCAQEAyMEdY1aR+sCR3ZSJrtztKTKqigvO/vBfqACJLZtS7QMgCGXJ6XIR
  yy7mx66W0/sOFa7/1mAZtEoIokDP3ShoqF4fVNb6XeqgQfaUHd8wJpDWHcR2OFwv
  plUUI1PLTktZ9uW2WE23b+ixNwJjJGwBDJPQEQFBE+vfmH0JP503wr5INS1poWg/
  j25sIWeYPHYeOrFp/eXaqhISP6G+q2IeTaWTXpwZj4LzXq5YOpk4bYEQ6mvRq7D1
  aHWfYmlEGepfaYR8Q0YqvvhYtMte3ITnuSJs171+GDqpdKcSwHnd6FudwGO4pcCO
  j4WcDuXc2CTHgH8gFTNhp/Y8/SpDOhvn9QIDAQAB
  -----END RSA PUBLIC KEY-----
  ```

#### 2. Production (Canlı) Environment
- **IP / Port**: `149.154.167.50:443`
- **Data Center**: `DC 2`
- **Public Key**:
  ```text
  -----BEGIN RSA PUBLIC KEY-----
  MIIBCgKCAQEA6LszBcC1LGzyr992NzE0ieY+BSaOW622Aa9Bd4ZHLl+TuFQ4lo4g
  5nKaMBwK/BIb9xUfg0Q29/2mgIR6Zr9krM7HjuIcCzFvDtr+L0GQjae9H0pRB2OO
  62cECs5HKhT5DZ98K33vmWiLowc621dQuwKWSQKjWf50XYFw42h21P2KXUGyp2y/
  +aEyZ+uVgLLQbRA1dEjSDZ2iGRy12Mk5gpYc397aYp438fsJoHIgJ2lgMv5h7WY9
  t6N/byY9Nw9p21Og3AoXSL2q/2IJ1WRUhebgAdGVMlV1fkuOQoEzR7EdpqtQD9Cs
  5+bfo3Nhmcyvk5ftB0WkJ9z6bNZ7yxrP8wIDAQAB
  -----END RSA PUBLIC KEY-----
  ```

### 3. User & Client Roster
- **User (Antigravity Operator) Telegram ID**: `8143462994` (Target for testing notifications and interactive commands).


