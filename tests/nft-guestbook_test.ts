import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.7.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.152.0/testing/asserts.ts';

// Contract constants
const MINT_PRICE = 1000000; // 1 STX in micro-STX
const MAX_MESSAGE_LENGTH = 280;

Clarinet.test({
  name: 'Ensure contract can be deployed',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const block = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-last-token-id', [], deployer.address),
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(0);
  },
});

Clarinet.test({
  name: 'Test successful minting with valid message and payment',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const message = "Hello, this is my first guestbook entry!";
    
    // Check initial state
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-last-token-id', [], deployer.address),
    ]);
    assertEquals(block1.receipts[0].result.expectOk().expectUint(0));
    
    // Mint an entry
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    
    // Check that minting succeeded
    assertEquals(block2.receipts.length, 1);
    block2.receipts[0].result.expectOk().expectUint(1);
    
    // Check that token ID incremented
    const block3 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-last-token-id', [], deployer.address),
    ]);
    block3.receipts[0].result.expectOk().expectUint(1);
    
    // Check entry details
    const block4 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-entry', [types.uint(1)], deployer.address),
    ]);
    const entry = block4.receipts[0].result.expectOk();
    entry.expectTuple({
      message: types.ascii(message),
      minter: types.principal(wallet1.address),
      block_height: types.uint(block4.height),
    });
  },
});

Clarinet.test({
  name: 'Test message length validation - exactly 280 characters',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create exactly 280 character message
    const message = "A".repeat(280);
    
    const block = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    
    // Should succeed
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: 'Test message length validation - too long message',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create 281 character message (too long)
    const message = "A".repeat(281);
    
    const block = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    
    // Should fail with ERR-MESSAGE-TOO-LONG
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(1002);
  },
});

Clarinet.test({
  name: 'Test payment verification - insufficient balance',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const message = "Test message";
    
    // Drain wallet balance to less than mint price
    chain.mineBlock([
      Tx.transfer(wallet1.balance - 1000, wallet1.address, deployer.address),
    ]);
    
    const block = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    
    // Should fail with ERR-INSUFFICIENT-PAYMENT
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(1003);
  },
});

Clarinet.test({
  name: 'Test token ID sequencing - multiple mints',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    const deployer = accounts.get('deployer')!;
    
    const message1 = "First message";
    const message2 = "Second message";
    const message3 = "Third message";
    
    // Mint three entries from different wallets
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message1)], wallet1.address),
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message2)], wallet2.address),
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message3)], wallet1.address),
    ]);
    
    // All should succeed with sequential IDs
    assertEquals(block1.receipts.length, 3);
    block1.receipts[0].result.expectOk().expectUint(1);
    block1.receipts[1].result.expectOk().expectUint(2);
    block1.receipts[2].result.expectOk().expectUint(3);
    
    // Check final token ID
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-last-token-id', [], deployer.address),
    ]);
    block2.receipts[0].result.expectOk().expectUint(3);
  },
});

Clarinet.test({
  name: 'Test transfer function is disabled',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    const message = "Test message";
    
    // First mint an entry
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    block1.receipts[0].result.expectOk().expectUint(1);
    
    // Try to transfer the NFT
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'transfer', [types.principal(wallet2.address), types.uint(1)], wallet1.address),
    ]);
    
    // Should fail with ERR-TRANSFER-DISABLED
    assertEquals(block2.receipts.length, 1);
    block2.receipts[0].result.expectErr().expectUint(1006);
  },
});

Clarinet.test({
  name: 'Test reading entries and owner information',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const deployer = accounts.get('deployer')!;
    const message = "Test message for reading";
    
    // Mint an entry
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    block1.receipts[0].result.expectOk().expectUint(1);
    
    // Test get-entry
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-entry', [types.uint(1)], deployer.address),
    ]);
    const entry = block2.receipts[0].result.expectOk();
    entry.expectTuple({
      message: types.ascii(message),
      minter: types.principal(wallet1.address),
      block_height: types.uint(block2.height),
    });
    
    // Test get-owner
    const block3 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-owner', [types.uint(1)], deployer.address),
    ]);
    block3.receipts[0].result.expectOk().expectPrincipal(wallet1.address);
    
    // Test get-token-uri
    const block4 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-token-uri', [types.uint(1)], deployer.address),
    ]);
    block4.receipts[0].result.expectOk().expectSome();
    
    // Test get-total-entries
    const block5 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-total-entries', [], deployer.address),
    ]);
    block5.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: 'Test edge cases - empty message and special characters',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test empty message
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii("")], wallet1.address),
    ]);
    block1.receipts[0].result.expectOk().expectUint(1);
    
    // Test message with special characters
    const specialMessage = "Hello! @#$%^&*()_+-=[]{}|;':\",./<>?";
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(specialMessage)], wallet1.address),
    ]);
    block2.receipts[0].result.expectOk().expectUint(2);
  },
});

Clarinet.test({
  name: 'Test non-existent token access',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Try to get non-existent entry
    const block1 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-entry', [types.uint(999)], deployer.address),
    ]);
    block1.receipts[0].result.expectErr().expectUint(1004);
    
    // Try to get owner of non-existent token
    const block2 = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'get-owner', [types.uint(999)], deployer.address),
    ]);
    block2.receipts[0].result.expectErr().expectUint(1004);
  },
});

Clarinet.test({
  name: 'Test payment transfer to contract owner',
  fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const message = "Test payment transfer";
    
    // Record initial balances
    const initialDeployerBalance = deployer.balance;
    const initialWalletBalance = wallet1.balance;
    
    // Mint an entry
    const block = chain.mineBlock([
      Tx.contractCall('nft-guestbook', 'mint-entry', [types.ascii(message)], wallet1.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Check that payment was transferred to deployer
    const finalDeployerBalance = deployer.balance;
    const finalWalletBalance = wallet1.balance;
    
    // Deployer should have received MINT_PRICE
    assertEquals(finalDeployerBalance, initialDeployerBalance + MINT_PRICE);
    // Wallet should have paid MINT_PRICE (plus transaction fees)
    assertEquals(finalWalletBalance < initialWalletBalance - MINT_PRICE, true);
  },
});
