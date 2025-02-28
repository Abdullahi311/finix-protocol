import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Test partial position closure",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Set price and create position
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-price', [
        types.ascii("AAPL"),
        types.uint(15000)
      ], deployer.address),
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(100000000),
        types.uint(4),
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    
    // Close 50% of position
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'partial-close', [
        types.uint(50)
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify position details
    const position = chain.callReadOnlyFn(
      'finix_core',
      'get-position',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    position.result.expectSome();
  }
});

Clarinet.test({
  name: "Test emergency pause mechanism",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Enable pause
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'toggle-pause', [], deployer.address)
    ]);
    block.receipts[0].result.expectOk();
    
    // Try creating position while paused
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(100000000),
        types.uint(4),
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectErr(types.uint(108));
  }
});
