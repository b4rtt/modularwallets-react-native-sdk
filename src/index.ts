import { NativeModules, Platform, NativeEventEmitter } from "react-native";

// Type definitions
export interface Credential {
  credentialId: string;
  userName: string;
}

export interface SmartAccount {
  accountId: string;
  address: string;
}

export interface TransactionResult {
  hash: string;
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
   * @param chain Blockchain network (e.g., "sepolia", "ethereum")
   * @param credential User credential from createUser or loginUser
   * @returns Promise resolving to smart account object
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
   * Send a transaction from the smart account
   * @param accountId Smart account ID from createSmartAccount
   * @param to Recipient address
   * @param value Amount in ETH to send
   * @returns Promise resolving to transaction result
   */
  sendTransaction: (
    accountId: string,
    to: string,
    value: string
  ): Promise<TransactionResult> => {
    return CircleModule.sendUserOperation(accountId, to, value);
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