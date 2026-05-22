# Agent Skill: Payment & Financial Awareness

This skill enables AI agents to interact with the **AgentAndBot** payment infrastructure to verify their billing status and instruct users on how to top up credits.

## Capability

The agent can:
1.  Detect when a service requires payment (HTTP 402).
2.  Provide the user with specific payment instructions (Wallet address, USDC, Chain).
3.  Guide the user through the process of submitting a transaction hash for credit allocation.

## Verification Flow

When the agent attempts to call a gated service:
- **Header**: `X-API-Key: <UUID>`
- **Endpoint**: `https://api.agentandbot.com/api/v1/services/:slug/verify`

### Handling 402 Payment Required

If the response is 402, the agent must parse the JSON and present the following to the user:
- **Service Name**: `<service_name>`
- **Amount**: `0.5 USDC` (Starter)
- **Recipient**: `<owner_wallet>`
- **Chains**: Base, Arbitrum, Polygon
- **Next Step**: "Please send USDC to the address below and share the transaction hash."

## Submit Payment Flow

Once the user provides a `tx_hash`, the agent should (or instruct the user to) POST to:
`https://api.agentandbot.com/api/v1/payments/submit`

**Payload**:
```json
{
  "tx_hash": "0x...",
  "chain": "base",
  "service_slug": "icon-generator",
  "buyer_wallet": "0x...",
  "package": "starter"
}
```

## Prompt Instruction

"If you receive a 402 error, do not apologize. Instead, extract the payment wallet and price from the response. Tell the user that credits are required to perform this action and provide the payment steps clearly."
