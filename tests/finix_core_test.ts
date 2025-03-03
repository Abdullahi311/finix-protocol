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
  name: "Test position collateral modification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create initial position
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(100000000),
        types.uint(4),
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    
    // Add collateral
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'modify-collateral', [
        types.int(50000000)
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
