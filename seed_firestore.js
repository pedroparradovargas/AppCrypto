const { execSync } = require('child_process');
const https = require('https');
const http = require('http');

const PROJECT_ID = 'vueltospay';

// Get access token from Firebase CLI
const token = execSync('npx firebase login:ci --no-localhost 2>/dev/null || echo ""', { encoding: 'utf-8' }).trim();

// Use the existing firebase auth token
function getAccessToken() {
  const result = execSync('npx firebase --non-interactive login:list --json 2>/dev/null', { encoding: 'utf-8' });
  return null; // fallback to REST with firebase token
}

// We'll use the Firestore REST API with the Firebase CLI token
function getFirebaseToken() {
  try {
    const path = require('path');
    const fs = require('fs');
    const home = process.env.HOME || process.env.USERPROFILE;
    const configPath = path.join(home, '.config', 'configstore', 'firebase-tools.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return config.tokens?.refresh_token || config.refreshToken;
  } catch (e) {
    console.error('Error leyendo config:', e.message);
    return null;
  }
}

async function getAccessTokenFromRefresh(refreshToken) {
  return new Promise((resolve, reject) => {
    const data = `grant_type=refresh_token&refresh_token=${encodeURIComponent(refreshToken)}&client_id=563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com&client_secret=j9iVZfS8kkCEFUPaAeJV0sAi`;
    const options = {
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(data),
      },
    };
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        const json = JSON.parse(body);
        resolve(json.access_token);
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function firestoreRequest(accessToken, method, path, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`,
      method,
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    };
    if (data) options.headers['Content-Length'] = Buffer.byteLength(data);

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        } else {
          resolve(JSON.parse(body || '{}'));
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreDoc(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

// Commit a batch of writes via Firestore REST
async function commitBatch(accessToken, writes) {
  const data = JSON.stringify({ writes });
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        else resolve(JSON.parse(body || '{}'));
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

const cryptos = [
  { id: 'bitcoin', name: 'Bitcoin', symbol: 'btc', image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png', price: 67500 },
  { id: 'ethereum', name: 'Ethereum', symbol: 'eth', image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png', price: 3450 },
  { id: 'solana', name: 'Solana', symbol: 'sol', image: 'https://assets.coingecko.com/coins/images/4128/large/solana.png', price: 145 },
  { id: 'cardano', name: 'Cardano', symbol: 'ada', image: 'https://assets.coingecko.com/coins/images/975/large/cardano.png', price: 0.45 },
  { id: 'ripple', name: 'XRP', symbol: 'xrp', image: 'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png', price: 0.52 },
  { id: 'polkadot', name: 'Polkadot', symbol: 'dot', image: 'https://assets.coingecko.com/coins/images/12171/large/polkadot.png', price: 7.20 },
  { id: 'dogecoin', name: 'Dogecoin', symbol: 'doge', image: 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png', price: 0.12 },
  { id: 'avalanche-2', name: 'Avalanche', symbol: 'avax', image: 'https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png', price: 35.50 },
];

const names = [
  'Carlos Martinez', 'Ana Garcia', 'Luis Rodriguez', 'Maria Lopez', 'Pedro Sanchez',
  'Laura Fernandez', 'Diego Torres', 'Sofia Ramirez', 'Juan Herrera', 'Valentina Cruz',
  'Andres Morales', 'Camila Vargas', 'Ricardo Mendez', 'Isabella Rojas', 'Fernando Castillo',
  'Daniela Ortiz', 'Santiago Reyes', 'Mariana Gutierrez', 'Alejandro Diaz', 'Natalia Paredes'
];

function randomBetween(min, max) { return Math.random() * (max - min) + min; }
function randomDate(daysBack) { return new Date(Date.now() - Math.random() * daysBack * 86400000); }
function pickRandom(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

async function seed() {
  const refreshToken = getFirebaseToken();
  if (!refreshToken) {
    console.error('No se encontro token de Firebase. Ejecuta: npx firebase login');
    process.exit(1);
  }

  console.log('Obteniendo access token...');
  const accessToken = await getAccessTokenFromRefresh(refreshToken);
  console.log('Token obtenido. Creando datos...');

  const writes = [];
  const docBase = `projects/${PROJECT_ID}/databases/(default)/documents`;

  for (let i = 0; i < 20; i++) {
    const uid = `synthetic_user_${String(i + 1).padStart(3, '0')}`;
    const name = names[i];
    const email = name.toLowerCase().replace(' ', '.') + '@demo.com';
    const createdAt = randomDate(90);
    const lastLogin = randomDate(7);

    // User profile
    writes.push({
      update: {
        name: `${docBase}/users/${uid}`,
        ...toFirestoreDoc({
          uid, email, displayName: name, photoUrl: null,
          biometricRegistered: Math.random() > 0.5,
          createdAt: createdAt.toISOString(),
          lastLogin: lastLogin.toISOString(),
        }),
      },
    });

    // Wallet
    const numCryptos = Math.floor(randomBetween(1, 5));
    const shuffled = [...cryptos].sort(() => Math.random() - 0.5);
    const userCryptos = shuffled.slice(0, numCryptos);
    const usdBalance = parseFloat(randomBetween(100, 15000).toFixed(2));

    const walletItems = userCryptos.map(c => ({
      currencyId: c.id, name: c.name, symbol: c.symbol, image: c.image,
      amount: parseFloat(randomBetween(0.001, c.price > 1000 ? 2 : 500).toFixed(8)),
      averageBuyPrice: parseFloat((c.price * randomBetween(0.8, 1.2)).toFixed(2)),
    }));

    writes.push({
      update: {
        name: `${docBase}/users/${uid}/data/wallet`,
        ...toFirestoreDoc({ items: walletItems, usdBalance }),
      },
    });

    // Transactions (3-8 per user)
    const numTx = Math.floor(randomBetween(3, 9));
    for (let t = 0; t < numTx; t++) {
      const crypto = pickRandom(userCryptos);
      const isBuy = Math.random() > 0.4;
      const amount = parseFloat(randomBetween(0.001, crypto.price > 1000 ? 1 : 200).toFixed(8));
      const pricePerUnit = parseFloat((crypto.price * randomBetween(0.85, 1.15)).toFixed(2));
      const totalValue = parseFloat((amount * pricePerUnit).toFixed(2));
      const txDate = randomDate(60);
      const txId = `${uid}_tx_${String(t + 1).padStart(3, '0')}`;

      writes.push({
        update: {
          name: `${docBase}/users/${uid}/transactions/${txId}`,
          ...toFirestoreDoc({
            id: txId, currencyId: crypto.id, currencyName: crypto.name,
            currencySymbol: crypto.symbol, currencyImage: crypto.image,
            type: isBuy ? 'buy' : 'sell', amount, pricePerUnit, totalValue,
            timestamp: txDate.toISOString(),
          }),
        },
      });
    }
  }

  // Firestore batch limit is 500 writes
  const batchSize = 500;
  for (let i = 0; i < writes.length; i += batchSize) {
    const chunk = writes.slice(i, i + batchSize);
    await commitBatch(accessToken, chunk);
    console.log(`Batch ${Math.floor(i / batchSize) + 1}: ${chunk.length} documentos escritos.`);
  }

  console.log(`\nTotal: ${writes.length} documentos creados para 20 usuarios.`);
}

seed().catch(console.error);
