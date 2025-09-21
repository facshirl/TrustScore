# TrustScore

TrustScore is an address reputation system smart contract for general trustworthiness scoring across all Stacks interactions. The contract maintains trust scores for addresses based on their interactions and behavior on the Stacks blockchain, providing a decentralized reputation system for the ecosystem.

## Features

- **Trust Score Management**: Initialize and track trust scores for any Stacks address (0-1000 scale)
- **Interaction Recording**: Record positive and negative interactions with weighted scoring
- **Authorization System**: Multi-level access control with contract owner and authorized evaluators
- **Comprehensive Tracking**: Monitor interaction history, positive/negative ratios, and timestamps
- **Trust Categories**: Automatic categorization (Poor, Fair, Good, Excellent) based on score ranges
- **Administrative Controls**: Contract enable/disable and bulk score updates for migration
- **Statistical Analytics**: Contract-wide statistics and individual address analytics

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Score Range**: 0-1000 (default: 500)
- **Weight Range**: 1-100 for interaction impact
- **Trust Categories**:
  - Poor: 0-250
  - Fair: 251-500
  - Good: 501-750
  - Excellent: 751-1000

## Installation

### Prerequisites

- Node.js (v16 or later)
- Clarinet CLI
- Stacks blockchain development environment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd TrustScore
```

2. Install dependencies:
```bash
cd TrustScore_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Watch mode for development:
```bash
npm run test:watch
```

## Usage Examples

### Initialize Trust Score

```clarity
;; Initialize a trust score for an address
(contract-call? .TrustScore initialize-trust-score 'SP1234567890)
```

### Record Interaction

```clarity
;; Record a positive interaction with weight 10
(contract-call? .TrustScore record-interaction
  'SP1234567890    ;; target address
  10               ;; positive score change
  u10              ;; weight (1-100)
  "successful-trade") ;; interaction type
```

### Query Trust Score

```clarity
;; Get basic trust score
(contract-call? .TrustScore get-trust-score 'SP1234567890)

;; Get complete trust data
(contract-call? .TrustScore get-trust-data 'SP1234567890)

;; Get trust category
(contract-call? .TrustScore get-trust-category 'SP1234567890)

;; Get trust percentage (0-100)
(contract-call? .TrustScore get-trust-percentage 'SP1234567890)
```

## Contract Functions Documentation

### Public Functions

#### `initialize-trust-score`
Initializes a trust score for a new address with default values.
- **Parameters**: `target` (principal)
- **Returns**: `(ok bool)` - true if initialized, false if already exists

#### `record-interaction`
Records a trust interaction and updates the target's score.
- **Parameters**:
  - `target` (principal) - Address being evaluated
  - `score-change` (int) - Score modification (-1000 to +1000)
  - `weight` (uint) - Impact weight (1-100)
  - `interaction-type` (string-ascii 50) - Description of interaction
- **Authorization**: Contract owner or authorized evaluators only
- **Returns**: `(ok uint)` - New trust score

#### `set-evaluator-authorization`
Grants or revokes evaluator permissions.
- **Parameters**: `evaluator` (principal), `authorized` (bool)
- **Authorization**: Contract owner only
- **Returns**: `(ok bool)`

#### `set-contract-enabled`
Enables or disables the contract functionality.
- **Parameters**: `enabled` (bool)
- **Authorization**: Contract owner only
- **Returns**: `(ok bool)`

#### `admin-set-score`
Directly sets a trust score for administrative purposes.
- **Parameters**: `target` (principal), `new-score` (uint)
- **Authorization**: Contract owner only
- **Returns**: `(ok bool)`

### Read-Only Functions

#### `get-trust-score`
Returns the current trust score for an address.
- **Parameters**: `target` (principal)
- **Returns**: `(ok uint)` - Trust score or default (500)

#### `get-trust-data`
Returns complete trust data structure for an address.
- **Parameters**: `target` (principal)
- **Returns**: Trust data object with score, interactions, and timestamps

#### `get-trust-category`
Returns the trust category classification.
- **Parameters**: `target` (principal)
- **Returns**: `(ok string)` - "Poor", "Fair", "Good", or "Excellent"

#### `is-authorized-evaluator`
Checks if an address has evaluator permissions.
- **Parameters**: `evaluator` (principal)
- **Returns**: `bool`

#### `get-contract-stats`
Returns contract-wide statistics.
- **Returns**: Object with total evaluations, enabled status, and owner

#### `get-interaction`
Retrieves specific interaction record.
- **Parameters**: `evaluator` (principal), `target` (principal), `block-number` (uint)
- **Returns**: Interaction data object

#### `get-trust-percentage`
Converts trust score to percentage (0-100).
- **Parameters**: `target` (principal)
- **Returns**: `(ok uint)` - Percentage value

## Deployment Guide

### Local Deployment

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Test basic functionality:
```clarity
(contract-call? .TrustScore initialize-trust-score tx-sender)
(contract-call? .TrustScore get-trust-score tx-sender)
```

### Testnet Deployment

1. Configure Clarinet.toml for testnet
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure for mainnet in Clarinet.toml
2. Deploy with production settings:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Controls
- **Contract Owner**: Full administrative access including score modifications and evaluator management
- **Authorized Evaluators**: Can record interactions and update scores within defined parameters
- **General Users**: Read-only access to trust scores and public data

### Security Considerations

1. **Authorization Validation**: All state-changing functions verify caller permissions
2. **Input Validation**: Score ranges and weights are validated against defined constants
3. **Score Bounds**: Trust scores are automatically clamped to valid ranges (0-1000)
4. **Contract Disabling**: Emergency stop functionality via contract-enabled flag
5. **Interaction History**: Immutable record of all trust evaluations for transparency

### Best Practices

- Regularly monitor authorized evaluators list
- Use appropriate weights for different interaction types
- Implement multi-signature for critical administrative functions
- Consider implementing rate limiting for high-frequency interactions
- Maintain off-chain backup of critical trust data

### Error Codes

- `u100` - ERR_UNAUTHORIZED: Insufficient permissions
- `u101` - ERR_INVALID_SCORE: Score outside valid range
- `u102` - ERR_SCORE_TOO_LOW: Score below minimum threshold
- `u103` - ERR_SCORE_TOO_HIGH: Score above maximum threshold
- `u104` - ERR_INVALID_WEIGHT: Weight outside valid range (1-100)

## Development

### Testing

Run the test suite:
```bash
npm test
```

Generate test coverage report:
```bash
npm run test:report
```

### Project Structure

```
TrustScore/
├── README.md
└── TrustScore_contract/
    ├── contracts/
    │   └── TrustScore.clar
    ├── tests/
    │   └── TrustScore.test.ts
    ├── package.json
    ├── tsconfig.json
    └── vitest.config.js
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

ISC License - See package.json for details