# Mainnet Deployment Guide

## Overview
This guide covers deploying your NFT Guestbook smart contract to the Stacks mainnet, verifying deployment, and handling redeployments.

## Prerequisites
- Stacks Wallet (Hiro Wallet or similar) with STX tokens
- Node.js and npm installed
- Clarinet CLI installed
- Your contract code ready and tested

## Step 1: Prepare Contract for Mainnet

### Update Contract Owner Address
Edit `contracts/nft-guestbook.clar` and replace the placeholder address:

```clarity
;; Contract owner (receives minting fees) - REPLACE WITH YOUR MAINNET ADDRESS  
(define-constant CONTRACT-OWNER 'YOUR_MAINNET_WALLET_ADDRESS_HERE)
```

**Important**: Replace `YOUR_MAINNET_WALLET_ADDRESS_HERE` with your actual mainnet wallet address.

### Get Your Mainnet Wallet Address
1. Open your Stacks Wallet (Hiro Wallet)
2. Copy your mainnet address (starts with `SM...`)
3. Use this address in the contract

## Step 2: Configure Mainnet Deployment

### Create Mainnet Configuration
Create `settings/Mainnet.toml`:

```toml
network = "mainnet"
[accounts.deployer]
mnemonic = "your 12-word wallet mnemonic phrase here"

[node]
rpc_url = "https://api.mainnet.hiro.so"
events_socket = "wss://api.mainnet.hiro.so"

[contracts.nft-guestbook]
path = "contracts/nft-guestbook.clar"
```

**Security Warning**: Never commit your mnemonic phrase to version control! Keep it secure.

### Alternative: Use Private Key
If you prefer using a private key instead of mnemonic:

```toml
[accounts.deployer]
private_key = "your_private_key_here"
```

## Step 3: Deploy to Mainnet

### Method 1: Using Clarinet CLI
```bash
# Deploy to mainnet
clarinet contract publish --mainnet

# Or specify configuration file
clarinet contract publish --manifest settings/Mainnet.toml
```

### Method 2: Using Stacks CLI
```bash
# Install stacks-cli if not already installed
npm install -g @stacks/cli

# Deploy contract
stacks-cli deploy --contract contracts/nft-guestbook.clar --mainnet
```

### Method 3: Using Hiro Wallet (Recommended for beginners)
1. Go to [Hiro Wallet](https://www.hiro.so/wallet)
2. Connect your wallet
3. Navigate to "Deploy Contract"
4. Upload your `nft-guestbook.clar` file
5. Confirm transaction

## Step 4: Verify Deployment

### Check on Stacks Explorer
1. Go to [Stacks Explorer](https://explorer.hiro.so/)
2. Search for your contract address
3. Verify contract is deployed

**Contract Address Format**: `SP1...your-address.nft-guestbook`

### Verify Contract Functions
Use the explorer's "Contract Call" tab to test:
- `get-last-token-id` - Should return `0`
- `get-total-entries` - Should return `0`

## Step 5: Update Frontend Configuration

### Update Environment Variables
Create `.env.production`:

```env
VITE_STACKS_API_URL=https://api.mainnet.hiro.so
VITE_NETWORK=mainnet
VITE_CONTRACT_ADDRESS=SP1...your-deployed-contract-address.nft-guestbook
```

### Update Contract Address in Frontend
In your frontend code, update the contract address:

```javascript
const contractAddress = 'SP1...your-deployed-contract-address.nft-guestbook';
```

## Redeployment Guide

### When to Redeploy
- Contract has bugs
- Need to add new features
- Security vulnerabilities found

### Redeployment Process

**Important**: Smart contracts on Stacks are immutable. You cannot update an existing contract. You must deploy a new contract.

#### Option 1: Deploy New Contract (Recommended)
1. Update contract name in `contracts/nft-guestbook-v2.clar`
2. Deploy as new contract: `nft-guestbook-v2`
3. Update frontend to use new contract address
4. Migrate data if needed

#### Option 2: Deploy to New Address
1. Keep same contract name
2. Deploy to new address
3. Update frontend configuration
4. Notify users of new contract address

### Contract Versioning Strategy
```clarity
;; Contract name with version
(define-constant CONTRACT_NAME "nft-guestbook-v2")
(define-constant CONTRACT_VERSION u2)

;; Add version check
(define-read-only (get-contract-version)
  (ok CONTRACT_VERSION))
```

## Post-Deployment Checklist

### Security Checklist
- [ ] Contract owner address is correct
- [ ] No test code remains
- [ ] Error handling is proper
- [ ] Gas costs are reasonable
- [ ] No hardcoded sensitive data

### Functionality Checklist
- [ ] Minting works correctly
- [ ] Message length validation works
- [ ] Transfer is properly disabled
- [ ] Read functions return correct data
- [ ] Error codes are meaningful

### Monitoring Setup
- Set up contract monitoring
- Track minting activity
- Monitor for unusual behavior
- Set up alerts for errors

## Troubleshooting

### Common Issues

#### 1. "Insufficient STX" Error
- Ensure your wallet has enough STX for deployment fees
- Mainnet deployment typically costs ~100-200 STX

#### 2. "Contract Already Exists" Error
- Contract name is already taken at that address
- Use a different contract name or deploy from different address

#### 3. "Invalid Principal" Error
- Check your wallet address format
- Ensure you're using mainnet address (starts with `SM...`)

#### 4. Transaction Fails
- Check network status
- Verify gas fees
- Ensure contract syntax is correct

### Getting Help
- [Stacks Discord](https://discord.gg/stacks)
- [Stacks Documentation](https://docs.stacks.co/)
- [Hiro Support](https://www.hiro.so/support)

## Cost Estimates

### Deployment Costs
- Contract deployment: ~100-200 STX
- Function calls: ~0.1-1 STX per call
- Storage costs: Varies by data stored

### Ongoing Costs
- No ongoing maintenance costs
- Users pay gas for transactions
- Consider setting reasonable mint fees

## Next Steps

1. **Test on Testnet First**: Always test on testnet before mainnet
2. **Security Audit**: Consider professional security audit
3. **Documentation**: Create user documentation
4. **Community**: Build community around your NFT project
5. **Marketing**: Promote your NFT guestbook

## Emergency Procedures

### If Contract Has Critical Bugs
1. Pause frontend immediately
2. Deploy new fixed contract
3. Communicate with users
4. Provide migration path if needed

### If Funds Are at Risk
1. Contact security team immediately
2. Document the issue
3. Communicate transparently
4. Consider emergency measures

---

**Remember**: Smart contracts are immutable. Test thoroughly before mainnet deployment!
