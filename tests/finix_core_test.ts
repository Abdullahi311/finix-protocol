import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test creating synthetic position with zero amounts",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Set price for test asset
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-price', [
        types.ascii("AAPL"),
        types.uint(15000) // $150.00
      ], deployer.address)
    ]);
    block.receipts[0].result.expectOk();

    // Try creating position with zero collateral
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(0),
        types.uint(4),
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectErr(types.uint(106));

    // Try creating position with zero synthetic amount
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(100000000),
        types.uint(0),
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectErr(types.uint(106));
  }
});

Clarinet.test({
  name: "Test admin parameter validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Try setting invalid liquidation ratio
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-liquidation-ratio', [
        types.uint(200) // Higher than minimum collateral ratio
      ], deployer.address)
    ]);
    block.receipts[0].result.expectErr(types.uint(107));

    // Try setting invalid liquidation penalty
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-liquidation-penalty', [
        types.uint(101) // Over 100%
      ], deployer.address)
    ]);
    block.receipts[0].result.expectErr(types.uint(107));
  }
});

[Previous tests remain unchanged...]
