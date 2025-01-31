import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test creating synthetic position",
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

    // Create position
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'create-position', [
        types.uint(100000000), // 100 STX collateral
        types.uint(4), // 4 synthetic shares
        types.ascii("AAPL")
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectOk();

    // Verify position
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'get-position', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);

    const position = block.receipts[0].result.expectSome();
    assertEquals(position['collateral-amount'], types.uint(100000000));
    assertEquals(position['synthetic-amount'], types.uint(4));
    assertEquals(position['asset-identifier'], types.ascii("AAPL"));
  }
});

Clarinet.test({
  name: "Test liquidation mechanism",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Set initial price and create position
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
    
    // Price spike makes position liquidatable
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-price', [
        types.ascii("AAPL"),
        types.uint(30000) // Price doubles
      ], deployer.address)
    ]);
    
    // Liquidate position
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'liquidate-position', [
        types.principal(wallet1.address)
      ], wallet2.address)
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify position is deleted
    block = chain.mineBlock([
      Tx.contractCall('finix_core', 'get-position', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    block.receipts[0].result.expectNone();
  }
});

Clarinet.test({
  name: "Test liquidation parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('finix_core', 'set-liquidation-ratio', [
        types.uint(110)
      ], deployer.address),
      Tx.contractCall('finix_core', 'set-liquidation-penalty', [
        types.uint(15)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
  }
});
