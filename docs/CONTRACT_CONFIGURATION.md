# Contract Configuration Guide

## Overview
This guide covers all the configuration items you need to update before deploying your NFT Guestbook contract to mainnet.

## Required Configuration Items

### 1. Contract Owner Address
**File**: `contracts/nft-guestbook.clar`  
**Line**: ~14

```clarity
;; BEFORE (placeholder)
(define-constant CONTRACT-OWNER 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; AFTER (your mainnet address)
(define-constant CONTRACT-OWNER 'SM...YOUR_MAINNET_WALLET_ADDRESS)
```

**How to get your mainnet address**:
1. Open Hiro Wallet
2. Switch to Mainnet (top right)
3. Copy your address (starts with `SM...`)
4. Replace the placeholder in the contract

### 2. Contract Metadata
**File**: `contracts/nft-guestbook.clar`  
**Line**: ~62

```clarity
;; BEFORE (placeholder)
(define-read-only (get-token-uri (token-id uint))
  (ok (some "https://example.com/metadata")))

;; AFTER (your metadata URL)
(define-read-only (get-token-uri (token-id uint))
  (ok (some "https://your-domain.com/api/metadata/{token_id}")))
```

**Metadata URL Options**:
- Static JSON file
- Dynamic API endpoint
- IPFS gateway URL
- Arweave URL

### 3. Mint Price (if adding payment)
**File**: `contracts/nft-guestbook.clar`  
**Line**: ~16

```clarity
;; Current setting (free minting)
(define-constant MINT-PRICE u1000000) ;; 1 STX in micro-STX

;; To change price (example: 5 STX)
(define-constant MINT-PRICE u5000000) ;; 5 STX in micro-STX
```

**Price calculations**:
- 1 STX = 1,000,000 micro-STX
- 0.1 STX = 100,000 micro-STX
- 10 STX = 10,000,000 micro-STX

## Optional Configuration Items

### 4. Message Length Limit
**File**: `contracts/nft-guestbook.clar`  
**Line**: ~20

```clarity
;; Current setting
(define-constant MAX-MESSAGE-LENGTH u280)

;; To change (example: Twitter-style)
(define-constant MAX-MESSAGE-LENGTH u280) ;; 280 characters

;; To change (example: Short messages)
(define-constant MAX-MESSAGE-LENGTH u140) ;; 140 characters
```

### 5. Error Codes
**File**: `contracts/nft-guestbook.clar`  
**Lines**: ~6-11

```clarity
;; Current error codes
(define-constant ERR-INVALID-MESSAGE (err u1001))
(define-constant ERR-MESSAGE-TOO-LONG (err u1002))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u1003))
(define-constant ERR-TOKEN-NOT-FOUND (err u1004))
(define-constant ERR-NOT-AUTHORIZED (err u1005))
(define-constant ERR-TRANSFER-DISABLED (err u1006))
```

**Customizing error codes**:
- Keep codes in 1000-1999 range for contract errors
- Document what each code means
- Update frontend error handling accordingly

## Frontend Configuration

### 6. Environment Variables
**File**: `.env.production`

```env
# Network Configuration
VITE_STACKS_API_URL=https://api.mainnet.hiro.so
VITE_NETWORK=mainnet

# Contract Configuration
VITE_CONTRACT_ADDRESS=SP...YOUR_CONTRACT_ADDRESS.nft-guestbook
VITE_CONTRACT_NAME=nft-guestbook

# Application Configuration
VITE_APP_NAME="NFT Guestbook"
VITE_APP_DESCRIPTION="Leave your message on the blockchain"
VITE_MINT_PRICE=1000000  # 1 STX in micro-STX

# Metadata Configuration
VITE_METADATA_BASE_URL=https://your-domain.com/api
VITE_TOKEN_IMAGE_BASE_URL=https://your-domain.com/images

# Social Links
VITE_TWITTER_HANDLE=your_twitter
VITE_DISCORD_INVITE=your_discord
VITE_WEBSITE_URL=https://your-domain.com
```

### 7. Contract Address in Frontend
**File**: `src/config/contract.js`

```javascript
// BEFORE (testnet)
export const CONTRACT_ADDRESS = 'ST1...testnet-address.nft-guestbook';
export const NETWORK = 'testnet';

// AFTER (mainnet)
export const CONTRACT_ADDRESS = 'SP...mainnet-address.nft-guestbook';
export const NETWORK = 'mainnet';
```

### 8. API Configuration
**File**: `src/config/api.js`

```javascript
// API endpoints
export const API_ENDPOINTS = {
  mainnet: 'https://api.mainnet.hiro.so',
  testnet: 'https://api.testnet.hiro.so',
  metadata: 'https://your-domain.com/api/metadata',
  images: 'https://your-domain.com/images'
};
```

## Deployment Configuration

### 9. Mainnet Deployment Settings
**File**: `settings/Mainnet.toml`

```toml
network = "mainnet"

[accounts.deployer]
mnemonic = "your 12-word mnemonic phrase here"

[node]
rpc_url = "https://api.mainnet.hiro.so"
events_socket = "wss://api.mainnet.hiro.so"

[contracts.nft-guestbook]
path = "contracts/nft-guestbook.clar"
clarity_version = 3

[deployment]
fee = 1000000  # 1 STX deployment fee
anchor_block = null  # Let system choose
```

### 10. Testnet Configuration (for testing)
**File**: `settings/Testnet.toml`

```toml
network = "testnet"

[accounts.deployer]
mnemonic = "your testnet mnemonic phrase here"

[node]
rpc_url = "https://api.testnet.hiro.so"
events_socket = "wss://api.testnet.hiro.so"

[contracts.nft-guestbook]
path = "contracts/nft-guestbook.clar"
clarity_version = 3
```

## Metadata Configuration

### 11. NFT Metadata Structure
**File**: `api/metadata/{token_id}.json`

```json
{
  "name": "NFT Guestbook Entry #1",
  "description": "A message left on the blockchain",
  "image": "https://your-domain.com/images/1.png",
  "external_url": "https://your-domain.com/entry/1",
  "attributes": [
    {
      "trait_type": "Message",
      "value": "Hello, world!"
    },
    {
      "trait_type": "Minter",
      "value": "SP...minter-address"
    },
    {
      "trait_type": "Timestamp",
      "value": "2024-01-26T18:00:00Z"
    }
  ],
  "properties": {
    "message": "Hello, world!",
    "minter": "SP...minter-address",
    "token_id": 1,
    "created_at": "2024-01-26T18:00:00Z"
  }
}
```

### 12. Image Generation
**Options for NFT images**:
- **Static images**: Pre-generated PNG/SVG files
- **Dynamic generation**: Server-side image generation
- **IPFS**: Decentralized storage
- **Text-based images**: Generate from message content

**Example image generation script**:
```javascript
// scripts/generate-image.js
function generateTokenImage(message, tokenId) {
  // Create canvas with message
  // Add token ID and timestamp
  // Return image URL or base64
}
```

## Security Configuration

### 13. Access Control
**File**: `contracts/nft-guestbook.clar`

```clarity
;; Add admin functions if needed
(define-constant ADMIN_ADDRESS 'SM...YOUR_ADMIN_ADDRESS)

(define-public (admin-function (param uint))
  (begin
    (asserts! (is-eq tx-sender ADMIN_ADDRESS) ERR-NOT-AUTHORIZED)
    ;; Admin logic here
    (ok true)))
```

### 14. Rate Limiting (Optional)
```clarity
;; Add rate limiting per address
(define-map minter-cooldowns
  { minter: principal }
  { last-mint: uint })

(define-public (mint-entry-with-cooldown (message (string-ascii 280)))
  (let ((new-token-id (+ (var-get last-token-id) u1))
        (current-block (block-height))
        (last-mint (default-to u0 (get? last-mint (map-get? minter-cooldowns { minter: tx-sender })))))
    (begin
      ;; Rate limit: 1 mint per 10 blocks
      (asserts! (>= (- current-block last-mint) u10) ERR-NOT-AUTHORIZED)
      
      ;; Update cooldown
      (map-set minter-cooldowns
        { minter: tx-sender }
        { last-mint: current-block })
      
      ;; Original mint logic
      (ok new-token-id))))
```

## Configuration Checklist

### Pre-Deployment Checklist
- [ ] Contract owner address updated
- [ ] Metadata URL configured
- [ ] Mint price set (if charging)
- [ ] Error codes documented
- [ ] Frontend environment variables set
- [ ] API endpoints configured
- [ ] Testnet deployment successful
- [ ] Security review completed

### Post-Deployment Checklist
- [ ] Contract verified on explorer
- [ ] Frontend connects to mainnet
- [ ] Metadata URLs accessible
- [ ] All functions working correctly
- [ ] Error handling tested
- [ ] Gas costs reasonable
- [ ] Documentation updated

## Configuration Templates

### Mainnet Template
```clarity
;; Contract configuration for mainnet deployment
(define-constant CONTRACT_OWNER 'SM...YOUR_MAINNET_ADDRESS)
(define-constant MINT_PRICE u1000000)  ; 1 STX
(define-constant MAX-MESSAGE-LENGTH u280)
(define-constant METADATA_URL "https://your-domain.com/api/metadata/{id}")
```

### Frontend Template
```javascript
// Mainnet configuration
export const CONFIG = {
  network: 'mainnet',
  contractAddress: 'SP...YOUR_CONTRACT_ADDRESS.nft-guestbook',
  apiUrl: 'https://api.mainnet.hiro.so',
  metadataUrl: 'https://your-domain.com/api/metadata',
  mintPrice: 1000000,  // 1 STX
  maxMessageLength: 280
};
```

## Troubleshooting Configuration

### Common Issues
1. **Wrong address format**: Use mainnet addresses (SM...), not testnet (ST...)
2. **Metadata URL not accessible**: Ensure URLs are publicly reachable
3. **Environment variables not loading**: Check .env file format
4. **Contract deployment fails**: Verify all constants are properly set

### Testing Configuration
1. Deploy to testnet first
2. Verify all functions work
3. Check metadata URLs
4. Test frontend integration
5. Only then deploy to mainnet

---

**Remember**: Always test your configuration on testnet before deploying to mainnet!
