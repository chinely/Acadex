# Acadex Smart Contract

## Overview

Acadex is a blockchain-based Academic Achievement Platform built on the Stacks blockchain using Clarity smart contract language. The platform enables educational institutions to manage student learning points, track academic achievements, and facilitate peer-to-peer transfers within an educational ecosystem.

## Features

- **Student Registration**: Secure registration system for learners with profile management
- **Learning Points System**: Token-based reward system for academic achievements
- **Authority Management**: Role-based access control for assessment authorities
- **Peer-to-Peer Transfers**: Students can transfer learning points between each other
- **Module Access Control**: Purchase-based access to educational modules
- **Emergency Controls**: Administrative halt functionality for system maintenance
- **Fee Management**: Configurable institutional processing fees

## Contract Architecture

### Core Components

1. **Learning Point Registry**: Tracks point balances for all registered participants
2. **Learner Profiles**: Stores participant information (name and identifier)
3. **Assessment Authorities**: Manages permissions for point deduction operations
4. **Administrative Controls**: Institution-level configuration management

### Key Constants

- `institution-administrator`: The deployer of the contract (has administrative privileges)
- **Error Codes**:
  - `u100`: Unauthorized operation
  - `u101`: Learner not registered
  - `u102`: Inadequate learning points
  - `u103`: Invalid point amount
  - `u104`: Registration process failed
  - `u105`: Action forbidden
  - `u106`: Invalid pricing structure
  - `u107`: Learner previously registered
  - `u108`: Invalid profile information
  - `u109`: Term halted

## Public Functions

### Student Functions

#### `register-participant`
```clarity
(register-participant (participant-name (string-ascii 55)) (participant-identifier (string-ascii 22)))
```
Registers a new participant in the system.
- **Parameters**: 
  - `participant-name`: Student's name (1-55 characters)
  - `participant-identifier`: Unique identifier (1-22 characters)
- **Returns**: `(ok true)` on success

#### `transfer-learning-points`
```clarity
(transfer-learning-points (recipient principal) (point-quantity uint))
```
Transfers learning points between registered participants.
- **Parameters**:
  - `recipient`: Principal address of the recipient
  - `point-quantity`: Number of points to transfer
- **Fee**: 1.5% processing fee (configurable)
- **Returns**: `(ok point-quantity)` on success

#### `purchase-module-access`
```clarity
(purchase-module-access (module-cost uint))
```
Purchases access to educational modules using learning points.
- **Parameters**:
  - `module-cost`: Base cost of the module
- **Cost**: `module-cost * module-pricing-multiplier`
- **Returns**: `(ok total-cost)` on success

### Administrative Functions

#### `allocate-learning-points`
```clarity
(allocate-learning-points (recipient principal) (point-quantity uint))
```
Allocates learning points to registered participants (admin only).

#### `update-module-pricing`
```clarity
(update-module-pricing (new-multiplier uint))
```
Updates the pricing multiplier for module purchases (admin only).

#### `modify-institutional-fee`
```clarity
(modify-institutional-fee (new-percentage uint))
```
Modifies the institutional processing fee (admin only, max 10%).

#### `authorize-assessment-authority`
```clarity
(authorize-assessment-authority (evaluator principal))
```
Grants assessment authority permissions to a registered participant (admin only).

#### `revoke-assessment-authority`
```clarity
(revoke-assessment-authority (evaluator principal))
```
Revokes assessment authority permissions (admin only).

#### `toggle-term-halt-status`
```clarity
(toggle-term-halt-status)
```
Emergency function to halt/resume system operations (admin only).

### Assessment Authority Functions

#### `deduct-learning-points`
```clarity
(deduct-learning-points (participant principal) (point-quantity uint))
```
Deducts learning points from participants (assessment authorities only).

## Read-Only Functions

### `retrieve-learning-point-total`
Returns the learning point balance for a given participant.

### `retrieve-learner-profile`
Returns the profile information for a registered participant.

### `retrieve-current-module-pricing`
Returns the current module pricing multiplier.

### `verify-assessment-authority`
Checks if a principal has assessment authority permissions.

### `verify-term-halt-status`
Returns the current halt status of the system.

## Usage Examples

### Register a New Student
```clarity
(contract-call? .acadex register-participant "John Doe" "STUDENT123")
```

### Transfer Points Between Students
```clarity
(contract-call? .acadex transfer-learning-points 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u100)
```

### Purchase Module Access
```clarity
(contract-call? .acadex purchase-module-access u50)
```

## Security Features

1. **Access Control**: Role-based permissions for different operations
2. **Input Validation**: Comprehensive validation for all parameters
3. **Emergency Halt**: System-wide halt mechanism for emergencies
4. **Fee Protection**: Maximum fee limits to prevent excessive charges
5. **Balance Verification**: Ensures sufficient funds before operations

## Configuration

- **Default institutional fee**: 1.5% (150 basis points)
- **Maximum institutional fee**: 10% (1000 basis points)
- **Module pricing multiplier**: Configurable by administrator
- **Profile constraints**: Names (1-55 chars), Identifiers (1-22 chars)

## Deployment

The contract is deployed with the deployer automatically set as the `institution-administrator`. This role cannot be transferred and has full administrative privileges.

## Error Handling

All functions return appropriate error codes for different failure scenarios. The contract includes comprehensive error handling for:
- Unauthorized access attempts
- Invalid input parameters
- Insufficient balances
- Registration conflicts
- System halt conditions

