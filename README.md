# BitcoinDAO - Decentralized Investment Fund

![Stacks](https://img.shields.io/badge/Stacks-Stack-blue)
![Clarity](https://img.shields.io/badge/Clarity-3.0-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Tests](https://img.shields.io/badge/Tests-Vitest-orange)

A sophisticated decentralized autonomous organization (DAO) built on the Stacks blockchain, enabling collective Bitcoin-backed investments through democratic governance and transparent fund management.

## 🎯 Overview

BitcoinDAO harnesses the security of Bitcoin through the Stacks layer-2 to create a trustless investment vehicle. Members stake STX tokens to gain voting rights, propose funding allocations, and collectively govern treasury distributions. The contract enforces time-locks, minimum thresholds, and democratic consensus to ensure responsible capital deployment while maintaining full transparency and decentralization principles.

## ✨ Features

### Core Functionality

- **Stake-Based Governance**: Members stake STX tokens to gain proportional voting power
- **Time-Lock Security**: Staked tokens are locked for a configurable period to prevent manipulation
- **Proposal System**: Members can create investment proposals with customizable parameters
- **Democratic Voting**: Token-weighted voting with transparent tallying
- **Automatic Execution**: Approved proposals are automatically executed from the treasury
- **Treasury Management**: Secure fund management with multi-signature-like consensus

### Security Features

- **Access Controls**: Owner-only initialization and member-only operations
- **Validation Guards**: Comprehensive parameter validation and state checks  
- **Reentrancy Protection**: Safe transfer patterns and state management
- **Time-Based Constraints**: Proposal duration limits and voting periods
- **Balance Verification**: Ensures sufficient funds before execution

## 🏗️ Architecture

### Smart Contract Components

#### State Variables

```clarity
total-staked          ; Total STX staked across all members
minimum-stake         ; Minimum required stake amount
lock-period          ; Time-lock duration for staked tokens
is-initialized       ; Contract initialization status
proposal-counter     ; Incrementing proposal identifier
```

#### Data Maps

- `member-stakes`: Maps member addresses to their voting power
- `stake-records`: Tracks stake amounts and unlock heights
- `investment-proposals`: Stores all proposal details and voting results
- `member-votes`: Prevents double-voting on proposals

#### Constants

- **Minimum Stake**: 1 STX (1,000,000 microSTX)
- **Lock Period**: ~10 days (1,440 blocks)
- **Proposal Duration**: 1-14 days (144-20,160 blocks)

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/) - Stacks smart contract development toolkit
- [Node.js](https://nodejs.org/) v16+ for running tests
- [Git](https://git-scm.com/) for version control

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/evans-fmt/bitcoin-dao.git
   cd bitcoin-dao
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify installation**

   ```bash
   clarinet check
   ```

### Development Setup

1. **Start Clarinet console**

   ```bash
   clarinet console
   ```

2. **Deploy to devnet**

   ```bash
   clarinet deployments generate --devnet
   clarinet deployments apply -p deployments/default.devnet-plan.yaml
   ```

## 🧪 Testing

The project uses Vitest with the Clarinet SDK for comprehensive testing.

### Run Tests

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Structure

```typescript
describe("BitcoinDAO Tests", () => {
  it("initializes correctly", () => {
    // Test initialization logic
  });
  
  it("handles staking operations", () => {
    // Test stake/unstake functionality
  });
  
  it("manages proposals and voting", () => {
    // Test governance mechanisms
  });
});
```

## 📖 Usage Guide

### For DAO Members

#### 1. Stake Tokens

```clarity
;; Stake 10 STX to join the DAO
(contract-call? .bitcoin-dao stake-tokens u10000000)
```

#### 2. Create Proposals

```clarity
;; Propose a 5 STX investment
(contract-call? .bitcoin-dao propose-investment
  "Fund DeFi Protocol Development"
  u5000000
  'SP1234567890ABCDEF
  u1440) ;; 10 days duration
```

#### 3. Vote on Proposals

```clarity
;; Vote in favor of proposal #1
(contract-call? .bitcoin-dao cast-vote u1 true)
```

#### 4. Execute Approved Proposals

```clarity
;; Execute proposal #1 after voting period
(contract-call? .bitcoin-dao execute-proposal u1)
```

#### 5. Unstake Tokens

```clarity
;; Unstake 5 STX after lock period
(contract-call? .bitcoin-dao unstake-tokens u5000000)
```

### For Contract Administrators

#### Initialize the DAO

```clarity
;; Must be called by contract owner
(contract-call? .bitcoin-dao initialize-dao)
```

## 🔍 API Reference

### Public Functions

#### `initialize-dao()`

Initializes the DAO contract (owner-only).

- **Access**: Contract owner only
- **Returns**: `(response bool uint)`

#### `stake-tokens(amount uint)`

Stakes STX tokens to gain voting rights.

- **Parameters**: `amount` - Amount in microSTX
- **Returns**: `(response bool uint)`
- **Requirements**: Amount ≥ minimum stake

#### `unstake-tokens(amount uint)`

Unstakes tokens after lock period expires.

- **Parameters**: `amount` - Amount to unstake in microSTX
- **Returns**: `(response bool uint)`
- **Requirements**: Tokens must be unlocked

#### `propose-investment(title, funding-amount, beneficiary, duration)`

Creates a new investment proposal.

- **Parameters**:
  - `title` - Proposal description (max 256 chars)
  - `funding-amount` - Requested amount in microSTX
  - `beneficiary` - Recipient address
  - `duration` - Voting period in blocks
- **Returns**: `(response uint uint)` - Proposal ID

#### `cast-vote(proposal-id, support)`

Casts a vote on an active proposal.

- **Parameters**:
  - `proposal-id` - Target proposal ID
  - `support` - Boolean vote (true = yes, false = no)
- **Returns**: `(response bool uint)`

#### `execute-proposal(proposal-id)`

Executes an approved proposal.

- **Parameters**: `proposal-id` - ID of proposal to execute
- **Returns**: `(response bool uint)`
- **Requirements**: Proposal approved and expired

### Read-Only Functions

#### `get-member-stake(member)`

Returns the voting power of a member.

#### `get-total-staked()`

Returns the total STX staked in the contract.

#### `get-proposal-details(proposal-id)`

Returns complete proposal information.

#### `get-treasury-balance()`

Returns the current contract treasury balance.

#### `get-dao-status()`

Returns overall DAO status and statistics.

## ⚠️ Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner-only operation |
| u101 | Contract not initialized |
| u102 | Contract already initialized |
| u103 | Insufficient balance |
| u105 | Unauthorized access |
| u106 | Proposal not found |
| u107 | Proposal expired |
| u108 | Already voted |
| u109 | Below minimum amount |
| u110 | Stake locked |
| u113 | Invalid amount |
| u114 | Invalid target |
| u115 | Invalid description |
| u116 | Invalid proposal ID |

## 🔒 Security Considerations

### Auditing Checklist

- [ ] Access control validation
- [ ] Integer overflow protection
- [ ] Reentrancy attack prevention
- [ ] Time manipulation resistance
- [ ] Balance validation accuracy
- [ ] Voting mechanism integrity

### Best Practices

- Always validate inputs before processing
- Use time-locks for sensitive operations
- Implement proper access controls
- Maintain transparent state transitions
- Regular security audits recommended

## 🛠️ Development Workflow

### Code Style

- Follow Clarity best practices
- Use descriptive variable names
- Include comprehensive comments
- Maintain consistent formatting

### Contribution Guidelines

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Run full test suite
5. Submit pull request with description

### Release Process

1. Update version numbers
2. Run comprehensive test suite
3. Perform security audit
4. Deploy to testnet
5. Community review period
6. Mainnet deployment

## 📊 Contract Metrics

### Gas Costs (Estimated)

- `stake-tokens`: ~2,500 units
- `cast-vote`: ~1,800 units  
- `propose-investment`: ~3,200 units
- `execute-proposal`: ~4,500 units
- `unstake-tokens`: ~2,800 units

### Storage Usage

- Fixed data: ~500 bytes
- Per member: ~200 bytes
- Per proposal: ~400 bytes

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to:

- Report bugs
- Suggest enhancements
- Submit code changes
- Participate in discussions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌐 Resources

### Documentation

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)

### Community

- [Stacks Discord](https://discord.gg/stacks)
- [Stacks Forum](https://forum.stacks.org/)
- [GitHub Issues](https://github.com/evans-fmt/bitcoin-dao/issues)

### Development Tools

- [Stacks Explorer](https://explorer.stacks.co/)
- [Sandbox](https://explorer.stacks.co/sandbox)
- [Hiro Platform](https://platform.hiro.so/)

---

**⚡ Built on Stacks • Secured by Bitcoin • Powered by Community**

*For questions, support, or collaboration opportunities, please reach out through our GitHub issues or community channels.*
