# Stacks Explorer Guide

## Overview
The Stacks Explorer is the primary tool for monitoring and verifying your smart contract deployments on the Stacks blockchain.

## Accessing Stacks Explorer

### Mainnet Explorer
- **URL**: [https://explorer.hiro.so/](https://explorer.hiro.so/)
- **Purpose**: View mainnet transactions and contracts

### Testnet Explorer
- **URL**: [https://explorer.stacks.co/](https://explorer.stacks.co/)
- **Purpose**: Test contract deployments before mainnet

## Finding Your Contract

### Method 1: Search by Contract Address
1. Go to [Stacks Explorer](https://explorer.hiro.so/)
2. Enter your contract address in the search bar
3. Contract address format: `SP1...your-address.nft-guestbook`

### Method 2: Search by Transaction ID
1. After deployment, copy the transaction ID
2. Paste it in the search bar
3. View deployment details

### Method 3: Search by Your Wallet Address
1. Search your wallet address
2. Look for "Contract Call" transactions
3. Find the deployment transaction

## Contract Details Page

### Overview Section
- **Contract Address**: Full contract identifier
- **Deployer**: Wallet address that deployed the contract
- **Block Height**: Block where contract was deployed
- **Transaction ID**: Deployment transaction hash

### Contract Code
- **Source Code**: View your deployed Clarity code
- **ABI**: Automatic function interface
- **State Variables**: Current contract state

### Functions Tab
View all callable functions:
- **Public Functions**: Can be called by anyone
- **Read-Only Functions**: Free to call, return data
- **Private Functions**: Internal contract functions

## Verifying Contract Deployment

### 1. Check Contract Exists
```
Search: SP1...your-address.nft-guestbook
Expected: Contract details page loads
```

### 2. Verify Contract Code
```
Tab: "Code"
Expected: Your nft-guestbook.clar code displayed
```

### 3. Test Read Functions
```
Tab: "Functions"
Function: get-last-token-id
Expected: Returns (ok 0)
```

### 4. Check Contract State
```
Tab: "State"
Expected: Shows token counter and metadata
```

## Monitoring Contract Activity

### Recent Transactions
1. Go to your contract page
2. Scroll to "Recent Transactions"
3. View all contract interactions

### Transaction Types
- **Contract Call**: Users calling contract functions
- **Mint**: New NFTs being created
- **Transfer**: STX transfers (if applicable)
- **Smart Contract**: Contract deployment

### Filter Transactions
- **All Transactions**: View all activity
- **Contract Calls**: Only function calls
- **STX Transfers**: Only STX transfers
- **Smart Contracts**: Contract deployments

## Testing Contract Functions

### Using Explorer's Contract Call Feature

#### Test get-last-token-id
1. Go to contract page
2. Click "Functions" tab
3. Find `get-last-token-id`
4. Click "Call Function"
5. Expected result: `(ok 0)`

#### Test get-total-entries
1. Find `get-total-entries` function
2. Click "Call Function"
3. Expected result: `(ok 0)`

#### Test Mint Function (Advanced)
1. Find `mint-entry` function
2. Enter test message: `"Hello World"`
3. Connect your wallet
4. Execute transaction
5. Expected: New NFT minted

## Understanding Transaction Details

### Transaction Page Components
- **Transaction ID**: Unique transaction hash
- **Status**: Success/Failed/Pending
- **Block**: Block number and timestamp
- **Sender**: Wallet that initiated transaction
- **Fee**: Gas cost paid
- **Events**: Contract events emitted

### Reading Transaction Results
```
Result: (ok 1)
Meaning: Function executed successfully, returned token ID 1
```

```
Result: (err 1002)
Meaning: Function failed with error code 1002 (message too long)
```

## Contract State Inspection

### Data Variables
View current values of contract variables:
- `last-token-id`: Current token counter
- Other data variables you defined

### Maps and NFTs
Inspect stored data:
- **Token Metadata**: View stored NFT metadata
- **Token Owners**: See who owns which tokens
- **Custom Maps**: Your contract's data storage

### NFT Details
For each minted token:
- **Token ID**: Unique identifier
- **Owner**: Current token holder
- **Metadata**: Stored message and minter info

## Advanced Explorer Features

### API Access
The Explorer provides API endpoints:
```javascript
// Get contract details
https://api.mainnet.hiro.so/v2/contracts/{contract_id}

// Get contract state
https://api.mainnet.hiro.so/v2/contracts/{contract_id}/state

// Get recent transactions
https://api.mainnet.hiro.so/v2/addresses/{address}/transactions
```

### Event Monitoring
Monitor contract events in real-time:
1. Go to contract page
2. Click "Events" tab
3. View emitted events
4. Filter by event type

### Contract Analytics
View usage statistics:
- Total transactions
- Unique users
- Gas usage
- Timeline of activity

## Troubleshooting Explorer Issues

### Contract Not Found
**Problem**: Search returns no results
**Solutions**:
- Verify contract address format
- Check if deployment succeeded
- Wait for block confirmation (1-2 blocks)

### Transaction Not Showing
**Problem**: Recent transaction not visible
**Solutions**:
- Refresh the page
- Check transaction status
- Wait for block confirmation

### Function Call Fails
**Problem**: Explorer function call returns error
**Solutions**:
- Check function parameters
- Ensure wallet is connected
- Verify sufficient STX balance

### State Not Updating
**Problem**: Contract state appears outdated
**Solutions**:
- Wait for block confirmation
- Check transaction succeeded
- Verify function executed correctly

## Best Practices

### Regular Monitoring
1. Check contract daily after launch
2. Monitor for unusual activity
3. Track gas costs and usage
4. Watch for error patterns

### Documentation
1. Save important transaction IDs
2. Document contract address
3. Record deployment details
4. Keep explorer screenshots

### Security Monitoring
1. Watch for unauthorized function calls
2. Monitor large transactions
3. Check for repeated failed attempts
4. Alert on unusual patterns

## Integration with Frontend

### Using Explorer Data
```javascript
// Fetch contract state from API
async function getContractState(contractId) {
  const response = await fetch(
    `https://api.mainnet.hiro.so/v2/contracts/${contractId}/state`
  );
  return response.json();
}

// Get recent transactions
async function getRecentTransactions(address) {
  const response = await fetch(
    `https://api.mainnet.hiro.so/v2/addresses/${address}/transactions`
  );
  return response.json();
}
```

### Link to Explorer
Create direct links from your frontend:
```html
<a href="https://explorer.hiro.so/tx/{transaction_id}">
  View on Explorer
</a>

<a href="https://explorer.hiro.so/contracts/{contract_id}">
  View Contract
</a>
```

## Mobile Access

### Mobile Browser
- Explorer works on mobile browsers
- Full functionality available
- Touch-friendly interface

### Mobile Apps
- **Hiro Wallet**: Built-in explorer
- **Stacks Wallet**: Transaction history
- **Third-party apps**: Various explorers available

## Additional Resources

### Official Documentation
- [Stacks Explorer Docs](https://docs.hiro.so/explorer)
- [API Documentation](https://docs.hiro.so/api)

### Community Resources
- [Stacks Discord](https://discord.gg/stacks)
- [Stacks Reddit](https://reddit.com/r/stacks)
- [Developer Forums](https://forum.stacks.co/)

### Alternative Explorers
- [Mempool Explorer](https://mempool.space/)
- [Blockchair](https://blockchair.com/)
- [Other third-party explorers](https://www.stacks.co/ecosystem)

---

**Pro Tip**: Bookmark your contract page for quick access and monitoring!
