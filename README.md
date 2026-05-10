# Wallpaper App with Rust Backend + Blockchain Premium

This project is now split into two parts:

```text
Flutter app        = mobile frontend
backend_rust/     = Rust API backend
Solana blockchain = premium payment verification
```

## What changed

The old app stored users and wallpaper data locally in Flutter. The backend logic has now been rebuilt in Rust.

The Rust backend handles:

- signup
- login
- profile update
- category API
- wallpaper API
- premium wallpaper rules
- Solana transaction verification
- premium unlock status

## Run the Rust backend

```bash
cd backend_rust
cargo run
```

For local UI testing without a real Solana transaction:

```bash
cd backend_rust
MOCK_BLOCKCHAIN_PAYMENTS=true cargo run
```

For production, set your wallet and RPC URL:

```bash
export MERCHANT_SOLANA_WALLET="YOUR_SOLANA_WALLET_ADDRESS"
export SOLANA_RPC_URL="https://api.mainnet-beta.solana.com"
export PREMIUM_PRICE_SOL="0.05"
cd backend_rust
cargo run
```

## Run Flutter

For Android emulator:

```bash
flutter pub get
flutter run
```

For a real phone, use your laptop/backend IP:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAPTOP_IP:8080
```

## Important production note

This is a working Rust backend structure, but before publishing commercially you should add:

- JWT/session tokens
- stronger password hashing such as Argon2
- database storage such as PostgreSQL
- HTTPS
- rate limiting
- admin panel for uploading wallpapers
