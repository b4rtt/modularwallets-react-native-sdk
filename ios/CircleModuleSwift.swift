import Foundation
import CircleModularWalletsCore

@objc(CircleModuleSwift)
class CircleModuleSwift: NSObject {
    
    // Singleton instance
    @objc static let shared = CircleModuleSwift()
    
    // Store references to objects that need to be kept alive
    private var bundlerClients: [String: BundlerClient] = [:]
    private var smartAccounts: [String: CircleSmartAccount] = [:]
    private var credentials: [String: Any] = [:]
    
    // MARK: - User Authentication
    
    @objc func createUserWithUserName(_ userName: String,
                                     clientKey: String,
                                     resolver: @escaping RCTPromiseResolveBlock,
                                     rejecter: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                // Create a PasskeyTransport with client key
                let transport = toPasskeyTransport(clientKey: clientKey)
                
                // Create WebAuthn credential
                let credential = try await toWebAuthnCredential(
                    transport: transport,
                    userName: userName,
                    mode: WebAuthnMode.register
                )
                
                // Store credential for later use
                let credentialId = UUID().uuidString
                credentials[credentialId] = credential
                
                // Convert credential to dictionary for JS
                let result: [String: Any] = [
                    "credentialId": credentialId,
                    "userName": userName
                ]
                
                resolver(result)
            } catch {
                rejecter("CREATE_USER_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    @objc func loginUserWithUserName(_ userName: String,
                                   clientKey: String,
                                   resolver: @escaping RCTPromiseResolveBlock,
                                   rejecter: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                // Create a PasskeyTransport with client key
                let transport = toPasskeyTransport(clientKey: clientKey)
                
                // Login with WebAuthn credential
                let credential = try await toWebAuthnCredential(
                    transport: transport,
                    userName: userName,
                    mode: WebAuthnMode.login
                )
                
                // Store credential for later use
                let credentialId = UUID().uuidString
                credentials[credentialId] = credential
                
                // Convert credential to dictionary for JS
                let result: [String: Any] = [
                    "credentialId": credentialId,
                    "userName": userName
                ]
                
                resolver(result)
            } catch {
                rejecter("LOGIN_USER_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Smart Account
    
    @objc func createSmartAccountWithClientKey(_ clientKey: String,
                                             clientUrl: String,
                                             chain: String,
                                             credential: NSDictionary,
                                             resolver: @escaping RCTPromiseResolveBlock,
                                             rejecter: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                // Get the credential from storage
                guard let credentialId = credential["credentialId"] as? String,
                      let storedCredential = credentials[credentialId] as? WebAuthnCredential else {
                    throw NSError(domain: "CircleModule", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"])
                }
                
                // Create WebAuthn account
                let webAuthnAccount = toWebAuthnAccount(storedCredential)
                
                // Create modular transport
                let modularTransport = toModularTransport(
                    clientKey: clientKey,
                    url: clientUrl
                )
                
                // Determine chain
                let chainObj: Chain
                switch chain.lowercased() {
                case "sepolia":
                    chainObj = Sepolia
                case "ethereum", "mainnet":
                    chainObj = Ethereum
                default:
                    chainObj = Sepolia // Default to Sepolia testnet
                }
                
                // Create bundler client
                let bundlerClient = BundlerClient(
                    chain: chainObj,
                    transport: modularTransport
                )
                
                // Create smart account
                let smartAccount = try await toCircleSmartAccount(
                    client: bundlerClient,
                    owner: webAuthnAccount
                )
                
                // Store references
                let accountId = UUID().uuidString
                bundlerClients[accountId] = bundlerClient
                smartAccounts[accountId] = smartAccount
                
                // Return account info
                let result: [String: Any] = [
                    "accountId": accountId,
                    "address": smartAccount.address
                ]
                
                resolver(result)
            } catch {
                rejecter("CREATE_ACCOUNT_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Transactions
    
    @objc func sendUserOperationWithAccountId(_ accountId: String,
                                                 to: String,
                                                 value: String,
                                                 resolver: @escaping RCTPromiseResolveBlock,
                                                 rejecter: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                // Get the stored account and client
                guard let bundlerClient = bundlerClients[accountId],
                      let account = smartAccounts[accountId] else {
                    throw NSError(domain: "CircleModule", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid account ID"])
                }
                
                // Parse value
                do {
                    let weiValue = try UnitUtils.parseEtherToWei(value)
                    
                    // Send user operation
                    let hash = try await bundlerClient.sendUserOperation(
                        account: account,
                        calls: [
                            EncodeCallDataArg(
                                to: to,
                                value: weiValue
                            )
                        ]
                    )
                    
                    // Return transaction hash
                    resolver(["hash": hash])
                } catch {
                    rejecter("PARSE_VALUE_ERROR", "Failed to parse ETH value: \(error.localizedDescription)", error)
                }
            } catch {
                rejecter("SEND_OPERATION_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Memory Management
    
    @objc func releaseCredential(_ credentialId: String,
                               resolver: @escaping RCTPromiseResolveBlock,
                               rejecter: @escaping RCTPromiseRejectBlock) {
        if credentials[credentialId] != nil {
            credentials.removeValue(forKey: credentialId)
            resolver(true)
        } else {
            resolver(false)
        }
    }
    
    @objc func releaseAccount(_ accountId: String,
                            resolver: @escaping RCTPromiseResolveBlock,
                            rejecter: @escaping RCTPromiseRejectBlock) {
        var removed = false
        
        if bundlerClients[accountId] != nil {
            bundlerClients.removeValue(forKey: accountId)
            removed = true
        }
        
        if smartAccounts[accountId] != nil {
            smartAccounts.removeValue(forKey: accountId)
            removed = true
        }
        
        resolver(removed)
    }
} 