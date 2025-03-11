# Circle Modular Wallets SDK for React Native

A React Native wrapper for Circle's Modular Wallets SDK, enabling mobile applications to integrate with Circle's blockchain infrastructure.

## Features

- User authentication with passkeys
- Smart account creation and management
- Transaction operations (native tokens and USDC)
- USDC transfers with built-in contract addresses
- Support for Polygon and Polygon Amoy networks
- Memory management for efficient resource usage
- **Zero-configuration** Swift Package Manager integration

## Installation

```bash
# Using npm
npm install modularwallets-react-native-sdk

# Using yarn
yarn add modularwallets-react-native-sdk
```

## Setup

### React Native Setup (without Expo)

1. Make sure your iOS deployment target is set to iOS 16.0 or higher in your Podfile:

```ruby
platform :ios, '16.0'
```

2. Install the pods:

```bash
cd ios && pod install
```

That's it! No need to manually open Xcode or add dependencies - everything is handled automatically. The Circle SDK is integrated via Swift Package Manager during the pod installation process.

### Expo Setup

If you're using Expo, this package includes a config plugin that will automatically:

1. Set the iOS deployment target to 16.0
2. Configure Swift Package Manager for the Circle SDK
3. Add Face ID usage description to Info.plist
4. Integrate the Circle SDK into your Xcode project

To use the plugin, add it to your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": [
      "modularwallets-react-native-sdk"
    ]
  }
}
```

#### Option 1: Local Development Build (Recommended)

This approach creates a development build locally on your machine without requiring an Expo account:

```bash
# Install expo-dev-client
npx expo install expo-dev-client

# Generate native code
npx expo prebuild

# Run on iOS simulator
npx expo run:ios

# OR for a physical device (requires Xcode)
npx expo run:ios --device
```

#### Option 2: Using EAS Build

If you prefer using Expo's cloud build service:

```bash
# Install expo-dev-client
npx expo install expo-dev-client

# Install EAS CLI if you haven't already
npm install -g eas-cli

# Log in to your Expo account
eas login

# Create a development build
eas build --profile development --platform ios
```

If using EAS, add this configuration to your `eas.json`:

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "resourceClass": "m-medium"
      }
    },
    "development-simulator": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true,
        "resourceClass": "m-medium"
      }
    }
  }
}
```

### Android Setup (Coming Soon)

Android support is planned for a future release.

## How It Works

This package automatically integrates the Circle Modular Wallets SDK using Swift Package Manager without requiring any manual configuration:

1. During installation, it creates the necessary Swift Package Manager configuration
2. It adds the Circle SDK GitHub repository as a Swift Package dependency
3. It integrates the package into your Xcode project
4. It ensures all dependencies are properly resolved

All of this happens automatically when you run `pod install` (React Native) or `npx expo prebuild` (Expo).

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

## Troubleshooting

### Build Issues

If you encounter build issues:

1. Make sure your iOS deployment target is set to 16.0 or higher
2. Try cleaning your build:
   ```bash
   # For React Native
   cd ios && pod deintegrate && pod install
   
   # For Expo
   npx expo prebuild --clean
   ```
3. Check that the Ruby gem 'xcodeproj' is installed:
   ```bash
   gem install xcodeproj
   ```

### Swift Package Manager Issues

If you see errors related to Swift Package Manager:

1. The package might be temporarily unavailable. Try again later.
2. Check your internet connection - Swift Package Manager needs to download the package.
3. If the issue persists, you can manually add the package in Xcode:
   ```bash
   open ios/YourProject.xcworkspace
   ```
   Then in Xcode: File > Add Package Dependencies > Enter "https://github.com/circlefin/modularwallets-ios-sdk.git"

### iOS Deployment Target Issues

If you see an error about the minimum deployment target:

```
Specs satisfying the dependency were found, but they required a higher minimum deployment target.
```

Make sure your iOS deployment target is set to 16.0 or higher in your Podfile:

```ruby
platform :ios, '16.0'
```

### Expo Users

If you're using Expo and encounter issues:

1. Make sure you're using a development build, not Expo Go (which doesn't support native modules)
2. Verify that the plugin is correctly added to your app.json
3. For local builds, try cleaning the project:
   ```bash
   npx expo prebuild --clean
   ```
4. For EAS builds, check your EAS build logs for specific errors

### Face ID/Touch ID Issues

If biometric authentication isn't working:

1. Make sure your app has the proper permissions in Info.plist
2. For simulator testing, enable Face ID in Features menu: Features > Face ID > Enrolled
3. For physical devices, ensure biometrics are set up on the device

## License

MIT
