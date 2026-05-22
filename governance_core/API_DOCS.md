# AgentAndBot API Documentation (v1)

Base URL: `https://api.agentandbot.com/api/v1`

## 1. List Services
`GET /services`

Returns all active services available for billing.

**Response (200 OK)**:
```json
{
  "services": [
    {
      "id": "uuid",
      "name": "SVG Icon Generator",
      "slug": "icon-generator",
      "owner_wallet": "0x...",
      "price_per_request": 5,
      "active": true
    }
  ]
}
```

## 2. Verify & Deduct Credits
`POST /services/:slug/verify`

**Headers**:
- `X-API-Key`: `<UUID>`

**Logic**:
Checks if the API key has credits for the specified service. If yes, deducts 1 credit and returns 200. If no, returns 402 with payment instructions.

**Response (200 OK)**:
```json
{
  "valid": true,
  "credits_remaining": 49,
  "service": "icon-generator"
}
```

**Response (402 Payment Required)**:
Returns full payment instructions including wallet address and pricing packages.

## 3. Submit Payment
`POST /payments/submit`

**Body**:
```json
{
  "tx_hash": "string",
  "chain": "base | arbitrum | polygon",
  "service_slug": "string",
  "buyer_wallet": "string",
  "package": "starter | basic | pro"
}
```

**Response (200 OK)**:
```json
{
  "api_key": "uuid",
  "credits_added": 50,
  "credits_remaining": 50,
  "package": "basic",
  "next_step": "Use api_key in X-API-Key header"
}
```

---
*Created for the AgentAndBot Infrastructure*
