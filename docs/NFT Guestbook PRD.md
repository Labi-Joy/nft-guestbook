# NFT Guestbook DApp - Product Requirements Document

## 1. Project Overview

### 1.1 Purpose
Build a simple NFT-based guestbook DApp on Stacks where users can mint NFTs with attached messages, creating a permanent on-chain record of their thoughts. This project serves as a learning tool for Clarity smart contracts and Stacks frontend development.

### 1.2 Target Users
- Stacks ecosystem learners
- NFT enthusiasts
- Anyone wanting to leave a permanent message on-chain

### 1.3 Success Criteria
- Successfully deploy contract to Stacks mainnet
- Users can connect wallet and mint NFTs with messages
- All messages are readable on-chain
- Total project cost under $5 USD

---

## 2. Smart Contract Specification

### 2.1 Contract Name
`nft-guestbook`

### 2.2 Contract Features

#### 2.2.1 NFT Standard
Implements SIP-009 NFT standard with the following traits:
- Sequential token IDs (starting at 1)
- Each NFT represents one guestbook entry
- Non-transferable (soul-bound to minter)

#### 2.2.2 Data Structures

**NFT Entries Map:**
```clarity
(define-map nft-entries 
  { token-id: uint } 
  { 
    message: (string-utf8 280),
    minter: principal,
    block-height: uint
  }
)
```

**State Variables:**
```clarity
(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)
```

**Constants:**
```clarity
(define-constant MINT-PRICE u1000000) ;; 1 STX
(define-constant MAX-MESSAGE-LENGTH u280)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MESSAGE-TOO-LONG (err u101))
(define-constant ERR-INVALID-TOKEN (err u102))
(define-constant ERR-PAYMENT-FAILED (err u103))
```

#### 2.2.3 Public Functions

**mint-entry**
- Parameters: `(message (string-utf8 280))`
- Validates message length
- Transfers 1 STX from minter to contract owner
- Mints NFT and stores message
- Returns: `(ok uint)` with token ID or error

**get-last-token-id**
- Read-only function
- Returns: `(ok uint)` current highest token ID

**get-entry**
- Parameters: `(token-id uint)`
- Read-only function
- Returns: `(optional { message, minter, block-height })`

**get-token-uri**
- Parameters: `(token-id uint)`
- Returns: `(ok (optional (string-ascii 256)))`
- Returns none (can be extended later)

**get-owner**
- Parameters: `(token-id uint)`
- Returns: `(ok (optional principal))`
- Returns minter's address

**transfer**
- Parameters: `(token-id uint) (sender principal) (recipient principal)`
- Returns: `(err u403)` - transfers are disabled

### 2.3 Contract Security Considerations
- All user inputs validated
- Mint price transferred before state changes
- No admin functions that could rug users
- Transfer function disabled (soul-bound)

---

## 3. Frontend Specification

### 3.1 Tech Stack
- **Framework:** React 18+ with Vite
- **Stacks Integration:** @stacks/connect, @stacks/transactions
- **Styling:** Tailwind CSS
- **State Management:** React hooks (useState, useEffect)

### 3.2 Pages & Components

#### 3.2.1 Main Page Layout
```
┌─────────────────────────────────────┐
│  Header                             │
│  [Connect Wallet Button]            │
├─────────────────────────────────────┤
│  Hero Section                       │
│  - App title & description          │
│  - Total entries counter            │
├─────────────────────────────────────┤
│  Mint Section (if wallet connected) │
│  - Message textarea (280 char max)  │
│  - Character counter                │
│  - [Mint for 1 STX] button          │
├─────────────────────────────────────┤
│  Guestbook Entries                  │
│  ┌─────────────────────────────┐   │
│  │ Entry #42                   │   │
│  │ "Hello from Lagos!"         │   │
│  │ By: SP2X...ABC              │   │
│  │ Block: 123456               │   │
│  └─────────────────────────────┘   │
│  [Load More]                        │
└─────────────────────────────────────┘
```

#### 3.2.2 Component Breakdown

**ConnectWallet Component**
- Shows "Connect Wallet" button when disconnected
- Shows abbreviated address when connected
- Handles authentication with Stacks wallet

**MintForm Component**
- Textarea for message input
- Real-time character counter
- Validation before submit
- Mint button with loading state
- Success/error notifications

**GuestbookEntry Component**
- Displays single entry card
- Shows: token ID, message, minter address, block height
- Responsive card design

**EntriesList Component**
- Fetches all entries from contract
- Pagination (10 entries per page)
- Loading skeleton states

### 3.3 User Flows

#### Flow 1: Connect Wallet
1. User clicks "Connect Wallet"
2. Hiro/Xverse wallet popup appears
3. User approves connection
4. UI updates to show connected address
5. Mint form becomes available

#### Flow 2: Mint Entry
1. User types message (max 280 chars)
2. Character counter updates in real-time
3. User clicks "Mint for 1 STX"
4. Wallet popup shows transaction details
5. User confirms transaction
6. Loading state shown
7. On success: confirmation message + new entry appears
8. On error: error message shown

#### Flow 3: View Entries
1. Page loads and fetches total entries
2. Fetches latest 10 entries
3. Displays entries with newest first
4. User scrolls and clicks "Load More"
5. Next 10 entries fetched and appended

---

## 4. Development Setup

### 4.1 Prerequisites
- Node.js 18+
- Clarinet CLI
- Hiro Wallet or Xverse Wallet (browser extension)
- Stacks mainnet address with STX

### 4.2 Project Structure
```
nft-guestbook/
├── contracts/
│   ├── nft-guestbook.clar
│   └── Clarinet.toml
├── tests/
│   └── nft-guestbook_test.ts
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ConnectWallet.jsx
│   │   │   ├── MintForm.jsx
│   │   │   ├── GuestbookEntry.jsx
│   │   │   └── EntriesList.jsx
│   │   ├── utils/
│   │   │   └── stacksApi.js
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
└── README.md
```

### 4.3 Environment Setup

**Step 1: Install Clarinet**
```bash
# macOS/Linux
brew install clarinet

# Or download from https://github.com/hirosystems/clarinet
```

**Step 2: Create Project**
```bash
clarinet new nft-guestbook
cd nft-guestbook
clarinet contract new nft-guestbook
```

**Step 3: Setup Frontend**
```bash
cd frontend
npm create vite@latest . -- --template react
npm install @stacks/connect @stacks/transactions @stacks/network
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### 4.4 Configuration Files

**Clarinet.toml**
```toml
[project]
name = "nft-guestbook"
requirements = []
[contracts.nft-guestbook]
path = "contracts/nft-guestbook.clar"
```

**frontend/.env**
```env
VITE_NETWORK=mainnet
VITE_CONTRACT_ADDRESS=SP[YOUR_ADDRESS_HERE]
VITE_CONTRACT_NAME=nft-guestbook
```

---

## 5. Testing Strategy

### 5.1 Smart Contract Testing

**Test Cases (Clarinet)**
1. ✓ Mint entry with valid message
2. ✓ Mint entry with maximum length message (280 chars)
3. ✓ Reject message exceeding 280 characters
4. ✓ Verify sequential token IDs
5. ✓ Verify payment transferred to owner
6. ✓ Retrieve entry by token ID
7. ✓ Verify transfer function is disabled
8. ✓ Multiple users can mint entries

**Sample Test File (tests/nft-guestbook_test.ts)**
```typescript
import { Clarinet, Tx, Chain, Account, types } from 'clarinet';

Clarinet.test({
  name: "Can mint entry with valid message",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        'nft-guestbook',
        'mint-entry',
        [types.utf8("Hello Stacks!")],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
  }
});
```

### 5.2 Frontend Testing

**Manual Testing Checklist**
- [ ] Wallet connection works on testnet
- [ ] Character counter updates correctly
- [ ] Mint button disabled when message empty
- [ ] Transaction popup shows correct amount (1 STX)
- [ ] Entries display correctly after minting
- [ ] Pagination loads more entries
- [ ] Mobile responsive design works

---

## 6. Deployment Guide

### 6.1 Deployment Prerequisites

**Required:**
- Stacks mainnet wallet with at least 2 STX
  - ~0.5-1 STX for contract deployment
  - ~0.5 STX for transaction fees buffer
  - Extra STX for testing mints

**Tools:**
- Clarinet CLI (for deployment)
- Stacks Explorer (for verification)

### 6.2 Testnet Deployment (Practice First!)

#### Step 1: Get Testnet STX
1. Visit https://explorer.hiro.so/sandbox/faucet?chain=testnet
2. Connect your wallet
3. Request testnet STX (free)
4. Wait for confirmation

#### Step 2: Deploy to Testnet
```bash
# Navigate to project
cd nft-guestbook

# Deploy contract
clarinet deployments generate --testnet
clarinet deployments apply --testnet

# Or use manual deployment
clarinet publish --testnet
```

#### Step 3: Verify Testnet Deployment
1. Copy your contract address from deployment output
2. Visit: https://explorer.hiro.so/?chain=testnet
3. Search for your address
4. Verify contract appears and is functional

#### Step 4: Test on Testnet
1. Update frontend `.env` with testnet contract details:
```env
VITE_NETWORK=testnet
VITE_CONTRACT_ADDRESS=ST[YOUR_TESTNET_ADDRESS]
VITE_CONTRACT_NAME=nft-guestbook
```
2. Run frontend: `npm run dev`
3. Connect wallet (switch to testnet in wallet settings)
4. Test minting several entries
5. Verify all functions work correctly

### 6.3 Mainnet Deployment

#### Step 1: Prepare Mainnet Wallet
```bash
# Check your mainnet STX balance
# Ensure you have at least 2 STX

# Recommended: Create new mainnet address for deployment
# This keeps your deployment wallet separate from personal wallet
```

#### Step 2: Final Contract Review
```bash
# Run all tests one final time
clarinet test

# Review contract code for any hardcoded testnet values
# Verify contract constants are correct
```

#### Step 3: Deploy to Mainnet

**Method A: Using Clarinet (Recommended)**
```bash
# Generate deployment plan
clarinet deployments generate --mainnet

# Review the generated deployment file
# File location: deployments/default.mainnet-plan.yaml

# Apply deployment
clarinet deployments apply --mainnet

# You'll be prompted to confirm
# Transaction will be broadcast to mainnet
```

**Method B: Using Hiro Platform**
```bash
# Alternative: Deploy via Hiro Platform
# 1. Visit https://platform.hiro.so
# 2. Create account and login
# 3. Click "Deploy Contract"
# 4. Paste your contract code
# 5. Connect wallet and confirm
```

#### Step 4: Save Deployment Information

**Create deployment.json**
```json
{
  "network": "mainnet",
  "contractAddress": "SP2X...", 
  "contractName": "nft-guestbook",
  "deploymentTxId": "0x123...",
  "deploymentBlock": 123456,
  "deploymentDate": "2026-01-26",
  "deployer": "SP2X...",
  "totalCost": "0.85 STX"
}
```

#### Step 5: Verify Mainnet Deployment

1. **Check Stacks Explorer**
   - Visit: https://explorer.hiro.so
   - Search: `[YOUR_ADDRESS].nft-guestbook`
   - Verify contract source code matches
   - Check deployment transaction status

2. **Test Read Functions**
```bash
# Use Clarinet console
clarinet console --mainnet

# Test read-only function
(contract-call? .nft-guestbook get-last-token-id)
# Should return (ok u0)
```

3. **Test First Mint (Optional)**
   - Use your frontend or Stacks Explorer
   - Mint first entry as test
   - Verify transaction succeeds
   - Check entry is readable

### 6.4 Frontend Deployment

#### Step 1: Update Production Config
```env
# frontend/.env.production
VITE_NETWORK=mainnet
VITE_CONTRACT_ADDRESS=SP[YOUR_ACTUAL_MAINNET_ADDRESS]
VITE_CONTRACT_NAME=nft-guestbook
```

#### Step 2: Build Frontend
```bash
cd frontend
npm run build
# Creates /dist folder with optimized files
```

#### Step 3: Deploy Frontend (Choose One)

**Option A: Vercel (Recommended)**
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Follow prompts
# Your app will be live at: https://your-app.vercel.app
```

**Option B: Netlify**
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod

# Drag and drop /dist folder or use CLI
```

**Option C: GitHub Pages**
```bash
# Install gh-pages
npm i -D gh-pages

# Add to package.json scripts:
# "deploy": "gh-pages -d dist"

npm run deploy
```

### 6.5 Redeployment Process

#### When to Redeploy
- Bug fixes in contract logic
- Adding new features
- Upgrading contract functionality

#### Important: Contracts are Immutable!
- You CANNOT update an existing contract
- You MUST deploy a NEW contract with a different name
- Old contract remains on-chain forever

#### Redeployment Steps

**Step 1: Plan Migration**
```clarity
// Option A: Deploy with version number
// Old: nft-guestbook
// New: nft-guestbook-v2

// Option B: Deploy with date
// New: nft-guestbook-20260201
```

**Step 2: Update Contract Name**
```bash
# Rename contract file
mv contracts/nft-guestbook.clar contracts/nft-guestbook-v2.clar

# Update Clarinet.toml
[contracts.nft-guestbook-v2]
path = "contracts/nft-guestbook-v2.clar"
```

**Step 3: Make Your Changes**
- Fix bugs or add features
- Update tests
- Run full test suite

**Step 4: Deploy New Version**
```bash
# Test on testnet first!
clarinet deployments generate --testnet
clarinet deployments apply --testnet

# After testing, deploy to mainnet
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

**Step 5: Update Frontend**
```env
# Update contract name in .env
VITE_CONTRACT_NAME=nft-guestbook-v2
```

**Step 6: Communicate to Users**
- Announce new contract address
- Old entries remain on old contract
- Users must use new contract for new entries

#### Migration Strategies

**Strategy 1: Clean Slate**
- Deploy new contract
- Start fresh with no data migration
- Simplest approach

**Strategy 2: Read-Only Old Contract**
- New contract for new mints
- Frontend reads from BOTH contracts
- Displays all historical + new entries
- More complex but preserves history

**Example: Reading from Multiple Contracts**
```javascript
// Fetch from both v1 and v2
const v1Entries = await fetchEntries('nft-guestbook');
const v2Entries = await fetchEntries('nft-guestbook-v2');
const allEntries = [...v1Entries, ...v2Entries].sort();
```

### 6.6 Post-Deployment Checklist

#### Immediate (Day 1)
- [ ] Contract deployed successfully to mainnet
- [ ] Contract visible on Stacks Explorer
- [ ] Frontend deployed and accessible
- [ ] First test mint successful
- [ ] All read functions working
- [ ] Wallet connection works on mainnet
- [ ] Deployment info saved (address, tx ID, cost)

#### Week 1
- [ ] Monitor for any transaction failures
- [ ] Check contract hasn't been exploited
- [ ] Verify STX payments reaching your wallet
- [ ] Gather user feedback
- [ ] Check gas costs are reasonable

#### Ongoing
- [ ] Monitor Stacks Explorer for activity
- [ ] Plan any needed v2 features
- [ ] Keep Clarinet and dependencies updated

### 6.7 Deployment Costs Breakdown

**Testnet:** FREE
- Testnet STX from faucet
- Unlimited testing

**Mainnet Estimates:**
- Contract deployment: 0.5-1.0 STX (~$0.50-$1.00)
- First test mint: 0.001 STX + 1 STX mint fee
- Transaction fees: ~0.001-0.01 STX per tx
- **Total first deployment: ~1.5-2 STX (~$1.50-$2.00)**

**Redeployment:**
- New contract: Same as initial (~0.5-1 STX)
- No way to "update" cheaper

### 6.8 Troubleshooting Deployment

**Issue: "Insufficient funds"**
- Ensure you have 2+ STX in wallet
- Check you're on correct network (mainnet)

**Issue: "Contract name already exists"**
- You've already deployed this contract name
- Choose new name (e.g., nft-guestbook-v2)

**Issue: "Transaction failed"**
- Check Stacks Explorer for error details
- Verify contract syntax is valid
- Ensure no testnet-specific code

**Issue: "Can't find contract on Explorer"**
- Wait 10-15 minutes for indexing
- Verify you're searching correct address format
- Check transaction was confirmed

**Issue: Frontend can't read contract**
- Verify contract address in .env is correct
- Check network setting matches (mainnet)
- Ensure contract is fully confirmed

---

## 7. Going Live

### 7.1 Launch Checklist
- [ ] Contract deployed to mainnet
- [ ] Frontend deployed and tested
- [ ] First successful mint completed
- [ ] Documentation written
- [ ] Share on Stacks Discord/Twitter
- [ ] Monitor first 24 hours

### 7.2 Future Enhancements
- Add IPFS for images alongside messages
- Allow message reactions/likes
- Create leaderboard of top contributors
- Add tipping functionality
- Enable message editing (new version only)
- Add message categories/tags

---

## 8. Resources

### Official Documentation
- Clarity Language: https://docs.stacks.co/clarity
- Stacks.js: https://stacks.js.org
- Clarinet: https://github.com/hirosystems/clarinet

### Tools
- Stacks Explorer: https://explorer.hiro.so
- Testnet Faucet: https://explorer.hiro.so/sandbox/faucet
- Hiro Platform: https://platform.hiro.so

### Community
- Discord: https://stacks.chat
- Forum: https://forum.stacks.org
- GitHub: https://github.com/stacks-network

---

## 9. Budget & Timeline

### Time Estimate
- Smart contract development: 4-6 hours
- Frontend development: 6-8 hours
- Testing (testnet): 2-3 hours
- Deployment & troubleshooting: 1-2 hours
- **Total: 13-19 hours (1-2 weekends)**

### Cost Estimate
- Development: $0 (free tools)
- Testnet testing: $0 (free testnet STX)
- Mainnet deployment: ~$1.50-$2.00
- Frontend hosting: $0 (free tier Vercel/Netlify)
- **Total: Under $5**

---

## Appendix A: Complete File Examples

### Contract: nft-guestbook.clar
```clarity
;; NFT Guestbook Contract
;; A simple guestbook where each entry is an NFT

;; SIP-009 NFT Trait
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MINT-PRICE u1000000) ;; 1 STX
(define-constant MAX-MESSAGE-LENGTH u280)

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MESSAGE-TOO-LONG (err u101))
(define-constant ERR-INVALID-TOKEN (err u102))
(define-constant ERR-PAYMENT-FAILED (err u103))
(define-constant ERR-TRANSFER-DISABLED (err u104))

;; Data vars
(define-data-var last-token-id uint u0)

;; Data maps
(define-map nft-entries 
  { token-id: uint } 
  { 
    message: (string-utf8 280),
    minter: principal,
    block-height: uint
  }
)

;; NFT token name
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (some (get minter (unwrap! (map-get? nft-entries {token-id: token-id}) (err ERR-INVALID-TOKEN)))))
)

;; Transfer - disabled for soul-bound tokens
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  ERR-TRANSFER-DISABLED
)

;; Get entry details
(define-read-only (get-entry (token-id uint))
  (map-get? nft-entries {token-id: token-id})
)

;; Mint new guestbook entry
(define-public (mint-entry (message (string-utf8 280)))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    ;; Validate message length
    (asserts! (<= (len message) MAX-MESSAGE-LENGTH) ERR-MESSAGE-TOO-LONG)
    
    ;; Transfer payment
    (unwrap! (stx-transfer? MINT-PRICE tx-sender CONTRACT-OWNER) ERR-PAYMENT-FAILED)
    
    ;; Store entry
    (map-set nft-entries
      {token-id: token-id}
      {
        message: message,
        minter: tx-sender,
        block-height: block-height
      }
    )
    
    ;; Update counter
    (var-set last-token-id token-id)
    
    (ok token-id)
  )
)
```

---

**END OF PRD**

*Last Updated: January 26, 2026*
*Version: 1.0*