import React, { useState } from 'react';
import { View, Text, Button, StyleSheet, Alert, TextInput, ScrollView } from 'react-native';
import CircleWallet, { Credential, SmartAccount, TransactionResult } from 'react-native-circle';

export default function CircleWalletDemo() {
  const [userName, setUserName] = useState('user@example.com');
  const [clientKey, setClientKey] = useState('YOUR_CIRCLE_API_KEY');
  const [clientUrl, setClientUrl] = useState('https://api.circle.com');
  const [recipientAddress, setRecipientAddress] = useState('0x1234567890123456789012345678901234567890');
  const [amount, setAmount] = useState('0.01');
  const [usdcAmount, setUsdcAmount] = useState('10'); // 10 USDC
  
  const [credential, setCredential] = useState<Credential | null>(null);
  const [account, setAccount] = useState<SmartAccount | null>(null);
  const [transactionResult, setTransactionResult] = useState<TransactionResult | null>(null);
  const [loading, setLoading] = useState(false);

  const createUser = async () => {
    try {
      setLoading(true);
      const result = await CircleWallet.createUser(userName, clientKey);
      setCredential(result);
      Alert.alert('Success', 'User created successfully');
    } catch (error) {
      Alert.alert('Error', `Failed to create user: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const loginUser = async () => {
    try {
      setLoading(true);
      const result = await CircleWallet.loginUser(userName, clientKey);
      setCredential(result);
      Alert.alert('Success', 'User logged in successfully');
    } catch (error) {
      Alert.alert('Error', `Failed to login: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const createSmartAccount = async () => {
    if (!credential) {
      Alert.alert('Error', 'Please create or login a user first');
      return;
    }

    try {
      setLoading(true);
      const result = await CircleWallet.createSmartAccount(
        clientKey,
        clientUrl,
        'polygonAmoy', // Using Polygon Amoy testnet
        credential
      );
      setAccount(result);
      Alert.alert('Success', `Smart account created with blockchain address: ${result.address}`);
    } catch (error) {
      Alert.alert('Error', `Failed to create smart account: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const sendTransaction = async () => {
    if (!account) {
      Alert.alert('Error', 'Please create a smart account first');
      return;
    }

    try {
      setLoading(true);
      // Note: We use the accountId (internal reference) here, not the blockchain address
      const result = await CircleWallet.sendTransaction(
        account.accountId, // This is the internal reference ID, not the blockchain address
        recipientAddress,
        amount
      );
      setTransactionResult(result);
      Alert.alert('Success', `Transaction sent: ${result.hash}\nTransaction Hash: ${result.transactionHash}`);
    } catch (error) {
      Alert.alert('Error', `Failed to send transaction: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const sendUSDC = async () => {
    if (!account) {
      Alert.alert('Error', 'Please create a smart account first');
      return;
    }

    try {
      setLoading(true);
      const result = await CircleWallet.sendUSDC(
        account.accountId,
        recipientAddress,
        usdcAmount,
        'polygonAmoy' // Using Polygon Amoy testnet
      );
      setTransactionResult(result);
      Alert.alert('Success', `USDC transaction sent: ${result.hash}\nTransaction Hash: ${result.transactionHash}`);
    } catch (error) {
      Alert.alert('Error', `Failed to send USDC: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const releaseCredential = async () => {
    if (!credential) {
      Alert.alert('Error', 'No credential to release');
      return;
    }

    try {
      setLoading(true);
      const result = await CircleWallet.releaseCredential(credential.credentialId);
      if (result) {
        setCredential(null);
        Alert.alert('Success', 'Credential released successfully');
      } else {
        Alert.alert('Warning', 'Credential not found or already released');
      }
    } catch (error) {
      Alert.alert('Error', `Failed to release credential: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const releaseAccount = async () => {
    if (!account) {
      Alert.alert('Error', 'No account to release');
      return;
    }

    try {
      setLoading(true);
      const result = await CircleWallet.releaseAccount(account.accountId);
      if (result) {
        setAccount(null);
        Alert.alert('Success', 'Account released successfully');
      } else {
        Alert.alert('Warning', 'Account not found or already released');
      }
    } catch (error) {
      Alert.alert('Error', `Failed to release account: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Circle Wallet Demo</Text>
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>User Name:</Text>
        <TextInput
          style={styles.input}
          value={userName}
          onChangeText={setUserName}
          placeholder="Enter user name"
        />
      </View>
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>Client Key:</Text>
        <TextInput
          style={styles.input}
          value={clientKey}
          onChangeText={setClientKey}
          placeholder="Enter Circle API key"
          secureTextEntry
        />
      </View>
      
      <View style={styles.buttonContainer}>
        <Button title="Create User" onPress={createUser} disabled={loading} />
        <Button title="Login User" onPress={loginUser} disabled={loading} />
      </View>
      
      {credential && (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>User Credential:</Text>
          <Text>Credential ID: {credential.credentialId}</Text>
          <Text>User Name: {credential.userName}</Text>
          <View style={styles.buttonContainer}>
            <Button title="Release Credential" onPress={releaseCredential} disabled={loading} />
          </View>
        </View>
      )}
      
      <View style={styles.separator} />
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>Client URL:</Text>
        <TextInput
          style={styles.input}
          value={clientUrl}
          onChangeText={setClientUrl}
          placeholder="Enter Circle API URL"
        />
      </View>
      
      <View style={styles.buttonContainer}>
        <Button
          title="Create Smart Account"
          onPress={createSmartAccount}
          disabled={loading || !credential}
        />
      </View>
      
      {account && (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>Smart Account:</Text>
          <Text>Internal Account ID: {account.accountId}</Text>
          <Text>Blockchain Address: {account.address}</Text>
          <Text style={styles.note}>Note: The Account ID is used internally by the plugin and is not your blockchain address.</Text>
          <View style={styles.buttonContainer}>
            <Button title="Release Account" onPress={releaseAccount} disabled={loading} />
          </View>
        </View>
      )}
      
      <View style={styles.separator} />
      
      <Text style={styles.sectionTitle}>Send Native Token (MATIC)</Text>
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>Recipient Address:</Text>
        <TextInput
          style={styles.input}
          value={recipientAddress}
          onChangeText={setRecipientAddress}
          placeholder="Enter recipient address"
        />
      </View>
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>Amount (MATIC):</Text>
        <TextInput
          style={styles.input}
          value={amount}
          onChangeText={setAmount}
          placeholder="Enter amount in MATIC"
          keyboardType="decimal-pad"
        />
      </View>
      
      <View style={styles.buttonContainer}>
        <Button
          title="Send MATIC"
          onPress={sendTransaction}
          disabled={loading || !account}
        />
      </View>
      
      <View style={styles.separator} />
      
      <Text style={styles.sectionTitle}>Send USDC</Text>
      
      <View style={styles.inputContainer}>
        <Text style={styles.label}>Amount (USDC):</Text>
        <TextInput
          style={styles.input}
          value={usdcAmount}
          onChangeText={setUsdcAmount}
          placeholder="Enter USDC amount"
          keyboardType="decimal-pad"
        />
      </View>
      
      <View style={styles.buttonContainer}>
        <Button
          title="Send USDC"
          onPress={sendUSDC}
          disabled={loading || !account}
        />
      </View>
      
      {transactionResult && (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>Transaction Result:</Text>
          <Text>User Operation Hash: {transactionResult.hash}</Text>
          <Text>Transaction Hash: {transactionResult.transactionHash}</Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  inputContainer: {
    marginBottom: 15,
  },
  label: {
    fontSize: 16,
    marginBottom: 5,
    fontWeight: '500',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 5,
    padding: 10,
    backgroundColor: '#fff',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginVertical: 10,
  },
  resultContainer: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 5,
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  resultTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  separator: {
    height: 1,
    backgroundColor: '#ddd',
    marginVertical: 20,
  },
  note: {
    fontStyle: 'italic',
    fontSize: 12,
    marginTop: 5,
    color: '#666',
  },
}); 