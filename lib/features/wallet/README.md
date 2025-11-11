# Wallet Feature

## Firestore Collection Structure

### Collection: `wallets`

Each document in the `wallets` collection represents a user's wallet and is identified by the user's ID.

#### Document Structure

```
wallets/{userId}
  ├── availableBalance: double (default: 0.0)
  ├── pendingBalance: double (default: 0.0)
  └── lastUpdated: Timestamp (server timestamp)
```

#### Field Descriptions

- **availableBalance**: The amount of money immediately available for withdrawal or spending
- **pendingBalance**: The amount of money that is being processed and not yet available
- **lastUpdated**: Timestamp of the last wallet update

#### Example Document

```json
{
  "availableBalance": 5000.00,
  "pendingBalance": 1500.00,
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

## Usage

### Create a Wallet

```dart
final walletRepository = sl<WalletRepository>();
await walletRepository.createWallet(userId);
```

### Get Wallet Balance

```dart
final result = await walletRepository.getWallet(userId);
result.fold(
  (failure) => print('Error: ${failure.failureMessage}'),
  (wallet) => print('Available: ${wallet.availableBalance}, Pending: ${wallet.pendingBalance}'),
);
```

### Update Balance

```dart
await walletRepository.updateBalance(userId, 5000.00, 1500.00);
```

### Watch Wallet Changes (Real-time)

```dart
walletRepository.watchWallet(userId).listen((result) {
  result.fold(
    (failure) => print('Error: ${failure.failureMessage}'),
    (wallet) => print('Balance updated: ${wallet.totalBalance}'),
  );
});
```
