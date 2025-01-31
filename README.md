# Finix Protocol

A decentralized protocol for creating and trading synthetic stocks on the Stacks blockchain.

## Overview
Finix allows users to create synthetic assets that track the price of real-world stocks. The protocol uses price oracles to maintain price parity with the underlying assets and enables permissionless trading of these synthetic assets.

## Features
- Create synthetic stocks backed by STX collateral
- Maintain price parity through oracles
- Trade synthetic assets permissionlessly
- Advanced liquidation mechanism with configurable parameters
- Incentivized liquidations with rewards for liquidators
- Governance controls for risk parameters

## Architecture
The protocol consists of the following key components:
- Core contract: Handles creation and management of synthetic positions
- Oracle contract: Provides price feeds for underlying assets 
- Liquidation mechanism: Automated system for managing undercollateralized positions

## Liquidation Mechanism
The protocol implements an advanced liquidation system with the following features:
- Configurable liquidation ratio (default 120%)
- Liquidation penalties to discourage risky positions
- Liquidator rewards to incentivize timely liquidations
- Automated distribution of penalties and rewards

Positions become eligible for liquidation when their collateral ratio falls below the liquidation threshold. Liquidators can trigger the liquidation process and receive a reward, while the remaining collateral (minus penalties) is returned to the position owner.

## Usage
[Documentation to be added]
