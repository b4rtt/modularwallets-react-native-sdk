# Circle Modular Wallets SDK for React Native

A React Native wrapper for Circle's Modular Wallets SDK, enabling mobile applications to integrate with Circle's blockchain infrastructure.

## Features

- User authentication with passkeys
- Smart account creation and management
- Transaction operations (native tokens and USDC)
- USDC transfers with built-in contract addresses
- Support for Polygon and Polygon Amoy networks
- Memory management for efficient resource usage

## Installation

```bash
# Using npm
npm install modularwallets-react-native-sdk

# Using yarn
yarn add modularwallets-react-native-sdk
```

### iOS Setup

1. Make sure your iOS deployment target is set to iOS 16.0 or higher in your Podfile:

```ruby
platform :ios, '16.0'
```

2. Install the pods:

```bash
cd ios && pod install
```

### Android Setup (Coming Soon)

Android support is planned for a future release.

## User Flow Overview

The typical integration flow for Circle Modular Wallets in your app is:

1. **User Registration/Login**: User creates or logs into your app using your existing authentication system
2. **Wallet Creation**: Upon successful authentication, create a Circle wallet with a passkey for the user
3. **Transaction Signing**: When the user wants to send USDC, they authorize the transaction with their passkey (biometric authentication)

This creates a seamless experience where:

- Users don't need to manage private keys or seed phrases
- Transactions are secured with biometric authentication (Face ID, Touch ID, etc.)
- The wallet is tied to the user's device through passkeys

## Integration Guide

### 1. Create a Wallet During User Onboarding

When a user creates an account in your app or logs in for the first time, create a Circle wallet for them:

```typescript
// After your app's user authentication is complete
const createWalletForUser = async (userId) => {
  try {
    // Create a passkey for the user
    // Use the user's ID or email as the username for the passkey
    const credential = await CircleWallet.createUser(
      userId, // or user email
      "YOUR_CIRCLE_API_KEY"
    );

    // Store the credential ID in your backend associated with the user
    await yourApi.storeCredentialForUser(userId, credential.credentialId);

    // Create a smart account for the user
    const account = await CircleWallet.createSmartAccount(
      "YOUR_CIRCLE_API_KEY",
      "https://api.circle.com",
      "polygonAmoy", // Use 'polygon' for mainnet
      credential
    );

    // Store the account ID in your backend associated with the user
    await yourApi.storeAccountForUser(
      userId,
      account.accountId,
      account.address
    );

    return { credential, account };
  } catch (error) {
    console.error("Error creating wallet:", error);
  }
};
```

### 2. Authenticate Returning Users

When a user returns to your app and has already created a wallet:

```typescript
const authenticateExistingUser = async (userId) => {
  try {
    // Retrieve the user's credential ID from your backend
    const credentialId = await yourApi.getCredentialIdForUser(userId);

    // Login with the user's passkey
    const credential = await CircleWallet.loginUser(
      userId, // or user email
      "YOUR_CIRCLE_API_KEY"
    );

    // Retrieve the user's account ID from your backend
    const accountInfo = await yourApi.getAccountForUser(userId);

    return {
      credential,
      accountId: accountInfo.accountId,
      address: accountInfo.address,
    };
  } catch (error) {
    console.error("Error authenticating user:", error);
  }
};
```

### 3. Send USDC Transactions

When a user wants to send USDC to another address:

```typescript
const sendUSDCTransaction = async (userId, recipientAddress, amount) => {
  try {
    // Get the user's account ID from your backend
    const accountInfo = await yourApi.getAccountForUser(userId);

    // Send USDC transaction
    // This will trigger a biometric authentication prompt for the user
    const result = await CircleWallet.sendUSDC(
      accountInfo.accountId,
      recipientAddress,
      amount,
      "polygonAmoy" // Use 'polygon' for mainnet
    );

    // Store transaction in your backend
    await yourApi.storeTransaction(userId, result.hash, result.transactionHash);

    return result;
  } catch (error) {
    console.error("Error sending USDC:", error);
  }
};
```

## API Reference

### `createUser(userName: string, clientKey: string): Promise<Credential>`

Creates a new user with passkey authentication. This will prompt the user for biometric authentication (Face ID, Touch ID, etc.) to create a passkey.

### `loginUser(userName: string, clientKey: string): Promise<Credential>`

Logs in an existing user with passkey authentication. This will prompt the user for biometric authentication to verify their identity.

### `createSmartAccount(clientKey: string, clientUrl: string, chain: string, credential: Credential): Promise<SmartAccount>`

Creates a smart account for the user. Returns an object containing:

- `accountId`: Internal reference ID used by the plugin (not the blockchain address)
- `address`: The actual blockchain address of the smart account

Supported chains:

- `polygon`: Polygon Mainnet
- `polygonAmoy`: Polygon Amoy Testnet

### `sendTransaction(accountId: string, to: string, value: string): Promise<TransactionResult>`

Sends a native token (MATIC) transaction from the smart account. The `accountId` parameter should be the internal reference ID returned from `createSmartAccount`, not the blockchain address. This will prompt the user for biometric authentication to sign the transaction.

Returns a `TransactionResult` containing:

- `hash`: The user operation hash
- `transactionHash`: The actual transaction hash on the blockchain

### `sendUSDC(accountId: string, to: string, amount: string, chainId: string): Promise<TransactionResult>`

Sends USDC from the smart account. This will prompt the user for biometric authentication to sign the transaction.

Parameters:

- `accountId`: Internal reference ID returned from `createSmartAccount`
- `to`: Recipient address
- `amount`: Amount of USDC to send (in USDC units)
- `chainId`: The chain ID or name (e.g., "polygon", "polygonAmoy")

Returns a `TransactionResult` containing:

- `hash`: The user operation hash
- `transactionHash`: The actual transaction hash on the blockchain

Supported chains for USDC:

- `polygon`: Polygon Mainnet USDC (0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359)
- `polygonAmoy`: Polygon Amoy Testnet USDC (0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582)

### `releaseCredential(credentialId: string): Promise<boolean>`

Releases a credential from memory when it's no longer needed. Returns `true` if the credential was found and released, `false` otherwise.

### `releaseAccount(accountId: string): Promise<boolean>`

Releases an account from memory when it's no longer needed. Returns `true` if the account was found and released, `false` otherwise.

### `addEventListener(eventName: string, callback: (event: any) => void)`

Adds an event listener for Circle events.

## Memory Management

The SDK stores references to credentials, accounts, and other resources in memory. To prevent memory leaks, it's recommended to release these resources when they're no longer needed:

1. Call `releaseCredential(credentialId)` when you're done with a credential
2. Call `releaseAccount(accountId)` when you're done with an account

This is especially important in long-running applications or when creating multiple accounts.

## User Experience Considerations

### Passkey Authentication

- Users will be prompted for biometric authentication (Face ID, Touch ID, etc.) when creating a wallet and signing transactions
- Passkeys are tied to the user's device and cannot be transferred
- If a user loses their device, they will need to create a new wallet on their new device

### Transaction Signing

- Each transaction requires biometric authentication
- Transactions are processed on the blockchain and may take time to confirm
- Gas fees are covered by the Circle paymaster, so users don't need to worry about having MATIC for gas

## License

MIT
