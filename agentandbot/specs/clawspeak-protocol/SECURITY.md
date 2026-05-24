# Security Policy - ClawSpeak Protocol

## 🛡 Security Philosophy
ClawSpeak is designed for high-density machine-to-machine communication. While the transit layer is encoded for machine efficiency, the protocol enforces absolute transparency through independent auditing.

## 🔍 Mandatory Human Oversight
- **The Decompiler Standard**: No production implementation of ClawSpeak shall exist without an attached Decompiler. All binary traffic MUST be logged and made available for human audit in real-time or via post-hoc analysis.
- **Audit Logs**: All nodes participating in a ClawSpeak swarm must maintain immutable audit logs of all encoded transmissions.

## 🛑 Governance & Protocol Evolution
The protocol DOES NOT evolve autonomously without human intervention.
- **Proposals**: Agents may suggest new tokens based on usage patterns.
- **Approval**: New tokens are only merged into the core specification after a "Human-in-the-Loop" review and manual commit to the repository.

## 🔐 Permissions and Scopes
ClawSpeak requires the following scopes for full functionality:
- `swarm_broadcast`: Used for discovery and consensus-checking within local networks.
- `network_fetch`: Used ONLY for fetching updated protocol schemas from verified sources (e.g., GitHub, ClawHub).

## Reporting a Vulnerability
If you discover a security vulnerability within this protocol or its reference implementations, please open a GitHub Issue or contact the Agentandbot Security Team.
