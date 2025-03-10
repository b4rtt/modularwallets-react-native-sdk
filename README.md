# Circle Modular Wallets SDK for React Native

A React Native wrapper for Circle's Modular Wallets SDK, enabling mobile applications to integrate with Circle's blockchain infrastructure.

## Features

- User authentication with passkeys
- Smart account creation and management
- Transaction operations
- Support for multiple blockchain networks
- Memory management for efficient resource usage

## Installation

```bash
# Using npm
npm install react-native-circle

# Using yarn
yarn add react-native-circle
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

## Usage

```typescript
import CircleWallet from 'react-native-circle';

// Create a new user with passkey authentication
const createUser = async () => {
  try {
    const credential = await CircleWallet.createUser(
      'user@example.com',
      'YOUR_CIRCLE_API_KEY'
    );
    console.log('User created:', credential);
    return credential;
  } catch (error) {
    console.error('Error creating user:', error);
  }
};

// Login an existing user
const loginUser = async () => {
  try {
    const credential = await CircleWallet.loginUser(
      'user@example.com',
      'YOUR_CIRCLE_API_KEY'
    );
    console.log('User logged in:', credential);
    return credential;
  } catch (error) {
    console.error('Error logging in:', error);
  }
};

// Create a smart account
const createSmartAccount = async (credential) => {
  try {
    const account = await CircleWallet.createSmartAccount(
      'YOUR_CIRCLE_API_KEY',
      'https://api.circle.com',
      'sepolia', // or 'ethereum' for mainnet
      credential
    );
    console.log('Smart account created:', account);
    // Note: account.accountId is an internal reference ID, not the blockchain address
    // The actual blockchain address is in account.address
    return account;
  } catch (error) {
    console.error('Error creating smart account:', error);
  }
};

// Send a transaction
const sendTransaction = async (account) => {
  try {
    // Note: We use the accountId (internal reference) here, not the blockchain address
    const result = await CircleWallet.sendTransaction(
      account.accountId, // This is the internal reference ID, not the blockchain address
      '0x1234567890123456789012345678901234567890', // recipient address
      '0.01' // amount in ETH
    );
    console.log('Transaction sent:', result);
    return result;
  } catch (error) {
    console.error('Error sending transaction:', error);
  }
};

// Release resources when no longer needed
const cleanup = async (credential, account) => {
  // Release credential from memory
  if (credential) {
    await CircleWallet.releaseCredential(credential.credentialId);
  }
  
  // Release account from memory
  if (account) {
    await CircleWallet.releaseAccount(account.accountId);
  }
};
```

## API Reference

### `createUser(userName: string, clientKey: string): Promise<Credential>`

Creates a new user with passkey authentication.

### `loginUser(userName: string, clientKey: string): Promise<Credential>`

Logs in an existing user with passkey authentication.

### `createSmartAccount(clientKey: string, clientUrl: string, chain: string, credential: Credential): Promise<SmartAccount>`

Creates a smart account for the user. Returns an object containing:
- `accountId`: Internal reference ID used by the plugin (not the blockchain address)
- `address`: The actual blockchain address of the smart account

### `sendTransaction(accountId: string, to: string, value: string): Promise<TransactionResult>`

Sends a transaction from the smart account. The `accountId` parameter should be the internal reference ID returned from `createSmartAccount`, not the blockchain address.

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

## License

MIT
