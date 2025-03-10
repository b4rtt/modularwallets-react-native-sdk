import { NativeModules, Platform, NativeEventEmitter } from "react-native";

// Type definitions
export interface Credential {
  credentialId: string;
  userName: string;
}

export interface SmartAccount {
  /**
   * Internal identifier used by the plugin to reference the account.
   * This is NOT the blockchain address, but a UUID used to look up the account in memory.
   */
  accountId: string;
  
  /**
   * The actual blockchain address of the smart account.
   * This is the address that will appear on the blockchain.
   */
  address: string;
}

export interface TransactionResult {
  /**
   * The user operation hash
   */
  hash: string;
  
  /**
   * The actual transaction hash on the blockchain
   */
  transactionHash: string;
}

// Get the native module
const CircleModule = NativeModules.CircleModule;
if (!CircleModule) {
  throw new Error("CircleModule is not available. Make sure the native module is properly linked.");
}

// Create event emitter
const eventEmitter = new NativeEventEmitter(CircleModule);

/**
 * Circle Modular Wallets SDK for React Native
 */
const CircleWallet = {
  /**
   * Create a new user with passkey authentication
   * @param userName User name for the passkey
   * @param clientKey Circle API client key
   * @returns Promise resolving to credential object
   */
  createUser: (userName: string, clientKey: string): Promise<Credential> => {
    return CircleModule.createUser(userName, clientKey);
  },

  /**
   * Login an existing user with passkey authentication
   * @param userName User name for the passkey
   * @param clientKey Circle API client key
   * @returns Promise resolving to credential object
   */
  loginUser: (userName: string, clientKey: string): Promise<Credential> => {
    return CircleModule.loginUser(userName, clientKey);
  },

  /**
   * Create a smart account for the user
   * @param clientKey Circle API client key
   * @param clientUrl Circle API client URL
   * @param chain Blockchain network (e.g., "polygonAmoy", "polygon")
   * @param credential User credential from createUser or loginUser
   * @returns Promise resolving to smart account object with accountId (internal reference) and address (blockchain address)
   */
  createSmartAccount: (
    clientKey: string,
    clientUrl: string,
    chain: string,
    credential: Credential
  ): Promise<SmartAccount> => {
    return CircleModule.createSmartAccount(clientKey, clientUrl, chain, credential);
  },

  /**
   * Send a native token transaction (e.g., MATIC) from the smart account
   * @param accountId Internal reference ID returned from createSmartAccount (NOT the blockchain address)
   * @param to Recipient address
   * @param value Amount in MATIC to send
   * @returns Promise resolving to transaction result with hash and transactionHash
   */
  sendTransaction: (
    accountId: string,
    to: string,
    value: string
  ): Promise<TransactionResult> => {
    return CircleModule.sendUserOperation(accountId, to, value);
  },

  /**
   * Send USDC from the smart account
   * @param accountId Internal reference ID returned from createSmartAccount (NOT the blockchain address)
   * @param to Recipient address
   * @param amount Amount of USDC to send (in USDC units, not wei)
   * @param chainId The chain ID or name (e.g., "polygon", "polygonAmoy")
   * @returns Promise resolving to transaction result with hash and transactionHash
   */
  sendUSDC: (
    accountId: string,
    to: string,
    amount: string,
    chainId: string
  ): Promise<TransactionResult> => {
    return CircleModule.sendUSDC(accountId, to, amount, chainId);
  },

  /**
   * Release a credential from memory when it's no longer needed
   * @param credentialId The credential ID to release
   * @returns Promise resolving to a boolean indicating whether the credential was found and released
   */
  releaseCredential: (credentialId: string): Promise<boolean> => {
    return CircleModule.releaseCredential(credentialId);
  },

  /**
   * Release an account from memory when it's no longer needed
   * @param accountId The account ID to release
   * @returns Promise resolving to a boolean indicating whether the account was found and released
   */
  releaseAccount: (accountId: string): Promise<boolean> => {
    return CircleModule.releaseAccount(accountId);
  },

  /**
   * Add event listener for Circle events
   * @param eventName Event name
   * @param callback Callback function
   * @returns Subscription object
   */
  addEventListener: (eventName: string, callback: (event: any) => void) => {
    return eventEmitter.addListener(eventName, callback);
  }
};

export default CircleWallet; 