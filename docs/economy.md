# Feature Specification: In-Game Ledger-Based Cryptocurrency System

## Overview

This feature introduces a cryptocurrency-inspired economic system for the MUD. The system is designed to emulate the behavior and user experience of a real-world cryptocurrency while remaining fully contained within the game environment.

The core concept is a **public, append-only ledger** of transactions tied to **player-controlled wallets**, forming a chain of records that can be inspected, analyzed, and interacted with by players.

This system is not intended to integrate with external blockchain networks or real-world financial systems.

---

## Goals

* Provide a cryptocurrency-like experience within the game
* Enable public visibility of all transactions
* Support wallet-based identity separate from player identity
* Enable emergent gameplay via economic transparency and pseudonymity
* Maintain high performance and low latency suitable for real-time gameplay
* Ensure system integrity via append-only ledger design

---

## Non-Goals

* Integration with real-world cryptocurrencies
* Decentralized consensus or mining
* Gas fees or transaction costs tied to infrastructure
* External wallet integrations (e.g., MetaMask)

---

## Core Concepts

### Wallet

A wallet is a container for holding and transferring currency. Wallets are not inherently tied to a player identity.

**Properties:**

* Unique wallet address (string)
* Owner (optional, may be hidden or unknown)
* Status (active, abandoned, destroyed)
* Created timestamp
* Archived/destroyed timestamp (optional)

**Capabilities:**

* Send and receive currency
* Be created or abandoned by players
* Be used pseudonymously

---

### Transaction

A transaction represents a transfer of currency between two wallets.

**Properties:**

* Transaction ID
* From wallet address
* To wallet address
* Amount
* Timestamp
* Optional memo or payload
* Previous transaction hash
* Transaction hash

**Rules:**

* Transactions are immutable once recorded
* Transactions must be validated before insertion

---

### Ledger

The ledger is an append-only sequence of all transactions.

**Characteristics:**

* Publicly viewable by all players
* Cannot be modified retroactively
* Serves as the single source of truth for all balances

---

### Block (Optional Phase 2)

Transactions may be grouped into blocks to simulate blockchain structure.

**Properties:**

* Block number
* Previous block hash
* Block hash
* Timestamp
* List of transactions

---

## Functional Requirements

### Wallet Management

* Players can create new wallets
* Players can list their wallets
* Players can abandon wallets
* Wallets persist in the ledger even after abandonment

---

### Transactions

* Players can transfer currency between wallets
* Transfers must validate sufficient balance
* Transfers are recorded as immutable ledger entries

---

### Ledger Visibility

* Players can view recent transactions
* Players can query transactions by ID
* Players can inspect wallet transaction history
* Players can inspect wallet balances

---

### Currency Issuance

* The system can mint currency via predefined mechanisms
* Minting events must be recorded as public transactions

---

### Currency Destruction

* Currency can be burned via a designated burn address
* Burn events must be recorded on the ledger

---

## Command Interface (MUD Commands)

### Wallet Commands

* `wallet create`
* `wallet list`
* `wallet abandon <address>`
* `wallet balance <address>`
* `wallet history <address>`

### Transaction Commands

* `wallet send <amount> <to_address>`

### Ledger Commands

* `chain latest`
* `chain tx <transaction_id>`
* `chain wallet <address>`
* `chain block <number>` (Phase 2)

---

## Data Model (Conceptual)

### wallets

* id
* address
* owner_id (nullable)
* status
* created_at
* archived_at

### transactions

* id
* from_wallet_id
* to_wallet_id
* amount
* hash
* previous_hash
* created_at
* memo

### blocks (optional)

* id
* block_number
* hash
* previous_hash
* created_at

---

## System Design

### Ledger Integrity

* Transactions are append-only
* No updates or deletions permitted
* Corrections must be performed via compensating transactions

### Balance Calculation

* Balances are derived from transaction history
* Cached balances may be used for performance

### Atomicity

* Transfers must be atomic operations
* Must prevent double-spending

---

## Security Considerations

* Ensure transaction authorization (player controls wallet)
* Prevent race conditions during transfers
* Protect against exploits or duplication

---

## Gameplay Implications

This system enables:

* Economic transparency
* Pseudonymous transactions
* Investigative gameplay (tracking funds)
* Emergent player-driven economies

---

## Future Enhancements

* Wallet keypairs and signature verification
* Transaction memos and metadata
* Block explorer UI
* Privacy mechanisms (mixers, obfuscation)
* Smart-contract-like systems (escrow, bounties)

---

## Implementation Phases

### Phase 1

* Wallet creation
* Transfers
* Public ledger
* Balance tracking

### Phase 2

* Block structure
* Advanced queries
* Wallet aliasing

### Phase 3

* Cryptographic signing
* Advanced economic tools

---

## Summary

This system provides a robust, scalable, and immersive economic framework that mirrors the behavior of cryptocurrencies while remaining optimized for gameplay and narrative flexibility.
