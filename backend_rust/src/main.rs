use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post, put},
    Json, Router,
};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::{
    collections::{HashMap, HashSet},
    env,
    net::SocketAddr,
    path::PathBuf,
    sync::Arc,
};
use tokio::{fs, sync::RwLock};
use tower_http::cors::CorsLayer;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    db_path: PathBuf,
    db: Arc<RwLock<AppDb>>,
    http: Client,
    merchant_wallet: String,
    solana_rpc_url: String,
    premium_price_lamports: u64,
    mock_blockchain_payments: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct AppDb {
    users: HashMap<String, UserRecord>,
    premium_users: HashSet<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct UserRecord {
    full_name: String,
    username: String,
    password_hash: String,
}

#[derive(Debug, Serialize)]
struct UserResponse {
    full_name: String,
    username: String,
    is_premium: bool,
}

#[derive(Debug, Deserialize)]
struct SignupRequest {
    full_name: String,
    username: String,
    password: String,
}

#[derive(Debug, Deserialize)]
struct LoginRequest {
    username: String,
    password: String,
}

#[derive(Debug, Deserialize)]
struct UpdateProfileRequest {
    full_name: String,
    password: Option<String>,
}

#[derive(Debug, Serialize)]
struct CategoryResponse {
    name: String,
    thumbnail_asset_path: String,
}

#[derive(Debug, Serialize, Clone)]
struct WallpaperResponse {
    id: String,
    category: String,
    asset_path: String,
    is_premium: bool,
}

#[derive(Debug, Serialize)]
struct WalletResponse {
    network: String,
    merchant_wallet: String,
    premium_price_sol: f64,
}

#[derive(Debug, Deserialize)]
struct VerifyPaymentRequest {
    username: String,
    customer_wallet: String,
    transaction_signature: String,
}

#[derive(Debug, Serialize)]
struct VerifyPaymentResponse {
    verified: bool,
    is_premium: bool,
    message: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let db_path = PathBuf::from(env::var("APP_DB_PATH").unwrap_or_else(|_| "data/app_state.json".to_string()));
    let db = load_db(&db_path).await.unwrap_or_default();

    let merchant_wallet = env::var("MERCHANTSOLANAWALLET")
        .unwrap_or_else(|_| "YOUR_SOLANA_WALLET_ADDRESS_HERE".to_string());
    let solana_rpc_url = env::var("SOLANARPCURL")
        .unwrap_or_else(|_| "https://api.devnet.solana.com".to_string());
    let premium_price_sol: f64 = env::var("PREMIUMPRICESOL")
        .unwrap_or_else(|_| "0.05".to_string())
        .parse()
        .unwrap_or(0.05);
    let premium_price_lamports = (premium_price_sol * 1_000_000_000_f64) as u64;
    let mock_blockchain_payments = env::var("MOCKBLOCKCHAINPAYMENTS")
        .map(|v| v.eq_ignore_ascii_case("true") || v == "1")
        .unwrap_or(false);

    let state = AppState {
        db_path,
        db: Arc::new(RwLock::new(db)),
        http: Client::new(),
        merchant_wallet,
        solana_rpc_url,
        premium_price_lamports,
        mock_blockchain_payments,
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/auth/signup", post(signup))
        .route("/auth/login", post(login))
        .route("/users/:username", get(get_user).put(update_profile))
        .route("/categories", get(categories))
        .route("/categories/:category/wallpapers", get(category_wallpapers))
        .route("/wallet", get(wallet))
        .route("/payments/verify", post(verify_payment))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let port: u16 = env::var("PORT")
    .unwrap_or_else(|_| "8080".to_string())
    .parse()
    .unwrap_or(8080);

let addr = SocketAddr::from(([0, 0, 0, 0], port));
println!("Wallpaper Rust backend running on http://{addr}");
axum::serve(tokio::net::TcpListener::bind(addr).await?, app).await?;

Ok(())
}

async fn load_db(path: &PathBuf) -> anyhow::Result<AppDb> {
    if !path.exists() {
        return Ok(AppDb::default());
    }
    let text = fs::read_to_string(path).await?;
    Ok(serde_json::from_str(&text)?)
}

async fn save_db(state: &AppState) -> anyhow::Result<()> {
    if let Some(parent) = state.db_path.parent() {
        fs::create_dir_all(parent).await?;
    }
    let db = state.db.read().await;
    let text = serde_json::to_string_pretty(&*db)?;
    fs::write(&state.db_path, text).await?;
    Ok(())
}

fn hash_password(password: &str) -> String {
    let mut hasher = Sha256::new();
    let salt = env::var("PASSWORD_HASH_SALT").unwrap_or_else(|_| "wallpaper-app-change-me".to_string());
    hasher.update(salt.as_bytes());
    hasher.update(password.as_bytes());
    hex::encode(hasher.finalize())
}

fn to_user_response(user: &UserRecord, premium_users: &HashSet<String>) -> UserResponse {
    UserResponse {
        full_name: user.full_name.clone(),
        username: user.username.clone(),
        is_premium: premium_users.contains(&user.username),
    }
}

async fn health() -> Json<Value> {
    Json(json!({ "status": "ok", "service": "wallpaper-rust-backend" }))
}

async fn signup(
    State(state): State<AppState>,
    Json(input): Json<SignupRequest>,
) -> Result<Json<UserResponse>, ApiError> {
    let full_name = input.full_name.trim().to_string();
    let username = input.username.trim().to_lowercase();
    if full_name.is_empty() || username.is_empty() || input.password.is_empty() {
        return Err(ApiError::bad_request("Full name, username and password are required"));
    }

    let mut db = state.db.write().await;
    if db.users.contains_key(&username) {
        return Err(ApiError::bad_request("Username already exists"));
    }

    let user = UserRecord {
        full_name,
        username: username.clone(),
        password_hash: hash_password(&input.password),
    };
    db.users.insert(username.clone(), user.clone());
    let premium_users = db.premium_users.clone();
    drop(db);
    save_db(&state).await.map_err(ApiError::internal)?;

    Ok(Json(to_user_response(&user, &premium_users)))
}

async fn login(
    State(state): State<AppState>,
    Json(input): Json<LoginRequest>,
) -> Result<Json<UserResponse>, ApiError> {
    let username = input.username.trim().to_lowercase();
    let db = state.db.read().await;
    let user = db
        .users
        .get(&username)
        .ok_or_else(|| ApiError::unauthorized("Invalid username or password"))?;

    if user.password_hash != hash_password(&input.password) {
        return Err(ApiError::unauthorized("Invalid username or password"));
    }

    Ok(Json(to_user_response(user, &db.premium_users)))
}

async fn get_user(
    State(state): State<AppState>,
    Path(username): Path<String>,
) -> Result<Json<UserResponse>, ApiError> {
    let db = state.db.read().await;
    let username = username.trim().to_lowercase();
    let user = db.users.get(&username).ok_or_else(|| ApiError::not_found("User not found"))?;
    Ok(Json(to_user_response(user, &db.premium_users)))
}

async fn update_profile(
    State(state): State<AppState>,
    Path(username): Path<String>,
    Json(input): Json<UpdateProfileRequest>,
) -> Result<Json<UserResponse>, ApiError> {
    let username = username.trim().to_lowercase();
    let mut db = state.db.write().await;
    let user = db.users.get_mut(&username).ok_or_else(|| ApiError::not_found("User not found"))?;

    if input.full_name.trim().is_empty() {
        return Err(ApiError::bad_request("Full name is required"));
    }

    user.full_name = input.full_name.trim().to_string();
    if let Some(password) = input.password {
        if !password.is_empty() {
            user.password_hash = hash_password(&password);
        }
    }
    let response_user = user.clone();
    let premium_users = db.premium_users.clone();
    drop(db);
    save_db(&state).await.map_err(ApiError::internal)?;

    Ok(Json(to_user_response(&response_user, &premium_users)))
}

async fn categories() -> Json<Vec<CategoryResponse>> {
    Json(vec![
        CategoryResponse { name: "3D".to_string(), thumbnail_asset_path: "assets/images.jpg".to_string() },
        CategoryResponse { name: "Nature".to_string(), thumbnail_asset_path: "assets/wp6835604.jpg".to_string() },
        CategoryResponse { name: "Anime".to_string(), thumbnail_asset_path: "assets/images5.jpg".to_string() },
    ])
}

async fn category_wallpapers(Path(category): Path<String>) -> Result<Json<Vec<WallpaperResponse>>, ApiError> {
    let items: Vec<WallpaperResponse> = all_wallpapers()
        .into_iter()
        .filter(|item| item.category.eq_ignore_ascii_case(&category))
        .collect();

    if items.is_empty() {
        return Err(ApiError::not_found("Category not found"));
    }

    Ok(Json(items))
}

async fn wallet(State(state): State<AppState>) -> Json<WalletResponse> {
    Json(WalletResponse {
        network: "Solana devnet/mainnet configurable by SOLANARPCURL".to_string(),
        merchant_wallet: state.merchant_wallet,
        premium_price_sol: state.premium_price_lamports as f64 / 1_000_000_000_f64,
    })
}

async fn verify_payment(
    State(state): State<AppState>,
    Json(input): Json<VerifyPaymentRequest>,
) -> Result<Json<VerifyPaymentResponse>, ApiError> {
    let username = input.username.trim().to_lowercase();
    if input.transaction_signature.trim().is_empty() {
        return Err(ApiError::bad_request("Transaction signature is required"));
    }

    {
        let db = state.db.read().await;
        if !db.users.contains_key(&username) {
            return Err(ApiError::not_found("User not found"));
        }
    }

    if state.merchant_wallet == "F9cjyfER8rzt1vUXBwbyLRaowPG1SUwnbqWzVQHN7Xzj" && !state.mock_blockchain_payments {
        return Err(ApiError::bad_request("Set MERCHANTSOLANAWALLET or enable MOCKBLOCKCHAINPAYMENTS for local testing"));
    }

    let verified = if state.mock_blockchain_payments {
        input.transaction_signature.trim().len() >= 12
    } else {
        verify_solana_transfer(
            &state,
            input.customer_wallet.trim(),
            input.transaction_signature.trim(),
        )
        .await?
    };

    if !verified {
        return Ok(Json(VerifyPaymentResponse {
            verified: false,
            is_premium: false,
            message: "Blockchain transaction could not be verified".to_string(),
        }));
    }

    let mut db = state.db.write().await;
    db.premium_users.insert(username);
    drop(db);
    save_db(&state).await.map_err(ApiError::internal)?;

    Ok(Json(VerifyPaymentResponse {
        verified: true,
        is_premium: true,
        message: "Payment verified. Premium wallpapers unlocked.".to_string(),
    }))
}

async fn verify_solana_transfer(
    state: &AppState,
    customer_wallet: &str,
    signature: &str,
) -> Result<bool, ApiError> {
    let body = json!({
        "jsonrpc": "2.0",
        "id": Uuid::new_v4().to_string(),
        "method": "getTransaction",
        "params": [
            signature,
            { "encoding": "jsonParsed", "maxSupportedTransactionVersion": 0 }
        ]
    });

    let response: Value = state
        .http
        .post(&state.solana_rpc_url)
        .json(&body)
        .send()
        .await
        .map_err(ApiError::internal)?
        .json()
        .await
        .map_err(ApiError::internal)?;

    let result = response.get("result").ok_or_else(|| ApiError::bad_request("Transaction not found on Solana RPC"))?;
    if result.is_null() {
        return Ok(false);
    }

    if !result.pointer("/meta/err").unwrap_or(&Value::Null).is_null() {
        return Ok(false);
    }

    let instructions = result
        .pointer("/transaction/message/instructions")
        .and_then(Value::as_array)
        .ok_or_else(|| ApiError::bad_request("Could not read transaction instructions"))?;

    for instruction in instructions {
        let info = instruction.pointer("/parsed/info").unwrap_or(&Value::Null);
        let destination_matches = info
            .get("destination")
            .and_then(Value::as_str)
            .map(|v| v == state.merchant_wallet)
            .unwrap_or(false);
        let source_matches = customer_wallet.is_empty()
            || info
                .get("source")
                .and_then(Value::as_str)
                .map(|v| v == customer_wallet)
                .unwrap_or(false);
        let lamports = info.get("lamports").and_then(Value::as_u64).unwrap_or(0);

        if destination_matches && source_matches && lamports >= state.premium_price_lamports {
            return Ok(true);
        }
    }

    Ok(false)
}

fn all_wallpapers() -> Vec<WallpaperResponse> {
    vec![
        WallpaperResponse { id: "3d-1".to_string(), category: "3D".to_string(), asset_path: "assets/unnamed.png".to_string(), is_premium: false },
        WallpaperResponse { id: "3d-2".to_string(), category: "3D".to_string(), asset_path: "assets/images1.jpg".to_string(), is_premium: true },
        WallpaperResponse { id: "nature-1".to_string(), category: "Nature".to_string(), asset_path: "assets/0e41dd403eae76a2e5d4abc02934c54e.jpg".to_string(), is_premium: false },
        WallpaperResponse { id: "nature-2".to_string(), category: "Nature".to_string(), asset_path: "assets/de2d16a4d4683a4d783a73d671fd11a7.jpg".to_string(), is_premium: true },
        WallpaperResponse { id: "anime-1".to_string(), category: "Anime".to_string(), asset_path: "assets/yaqGvs.jpg".to_string(), is_premium: false },
        WallpaperResponse { id: "anime-2".to_string(), category: "Anime".to_string(), asset_path: "assets/43afd01dc42127c352f1fde070cc2be0.jpg".to_string(), is_premium: true },
    ]
}

#[derive(Debug)]
struct ApiError {
    status: StatusCode,
    message: String,
}

impl ApiError {
    fn bad_request(message: impl Into<String>) -> Self {
        Self { status: StatusCode::BAD_REQUEST, message: message.into() }
    }

    fn unauthorized(message: impl Into<String>) -> Self {
        Self { status: StatusCode::UNAUTHORIZED, message: message.into() }
    }

    fn not_found(message: impl Into<String>) -> Self {
        Self { status: StatusCode::NOT_FOUND, message: message.into() }
    }

    fn internal(error: impl std::fmt::Display) -> Self {
        Self { status: StatusCode::INTERNAL_SERVER_ERROR, message: error.to_string() }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> axum::response::Response {
        (self.status, Json(json!({ "error": self.message }))).into_response()
    }
}


