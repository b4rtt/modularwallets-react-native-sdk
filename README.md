# Circle Modular Wallets SDK for React Native

A React Native wrapper for Circle's Modular Wallets SDK, enabling mobile applications to integrate with Circle's blockchain infrastructure.

## Features

- User authentication with passkeys
- Smart account creation and management
- Transaction operations
- Support for multiple blockchain networks

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
    return account;
  } catch (error) {
    console.error('Error creating smart account:', error);
  }
};

// Send a transaction
const sendTransaction = async (account) => {
  try {
    const result = await CircleWallet.sendTransaction(
      account.accountId,
      '0x1234567890123456789012345678901234567890', // recipient address
      '0.01' // amount in ETH
    );
    console.log('Transaction sent:', result);
    return result;
  } catch (error) {
    console.error('Error sending transaction:', error);
  }
};
```

## API Reference

### `createUser(userName: string, clientKey: string): Promise<Credential>`

Creates a new user with passkey authentication.

### `loginUser(userName: string, clientKey: string): Promise<Credential>`

Logs in an existing user with passkey authentication.

### `createSmartAccount(clientKey: string, clientUrl: string, chain: string, credential: Credential): Promise<SmartAccount>`

Creates a smart account for the user.

### `sendTransaction(accountId: string, to: string, value: string): Promise<TransactionResult>`

Sends a transaction from the smart account.

### `addEventListener(eventName: string, callback: (event: any) => void)`

Adds an event listener for Circle events.

## License

MIT
