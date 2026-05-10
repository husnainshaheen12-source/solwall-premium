# Wallpaper App Rust Backend

This is the Rust backend/API for the Flutter wallpaper app.

It replaces the old local-only Flutter storage with a real API layer for:

- Signup
- Login
- Profile update
- Category listing
- Wallpaper listing
- Premium status
- Solana blockchain payment verification

## Run locally

```bash
cd backend_rust
cargo run
```

The server starts on:

```text
http://127.0.0.1:8080
```

For Android emulator, the Flutter app uses:

```text
http://10.0.2.2:8080
```

For a real Android/iPhone device, run the backend on your laptop and start Flutter with your laptop LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAPTOP_IP:8080
```

## Blockchain settings

Set your real Solana merchant wallet before production use:

```bash
export MERCHANT_SOLANA_WALLET="YOUR_SOLANA_WALLET_ADDRESS"
export SOLANA_RPC_URL="https://api.devnet.solana.com"
export PREMIUM_PRICE_SOL="0.05"
```

For local UI testing only, you can allow mock signatures:

```bash
export MOCK_BLOCKCHAIN_PAYMENTS=true
cargo run
```

Do **not** enable `MOCK_BLOCKCHAIN_PAYMENTS=true` in production.

## Payment verification

`POST /payments/verify` accepts:

```json
{
  "username": "hassan",
  "customer_wallet": "customer wallet address",
  "transaction_signature": "solana transaction signature"
}
```

The backend checks the Solana transaction and unlocks premium access only when the transaction transfers the required SOL amount to your merchant wallet.
