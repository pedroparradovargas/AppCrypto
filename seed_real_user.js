const https = require('https');
const path = require('path');
const fs = require('fs');

const PROJECT_ID = 'vueltospay';
const REAL_UID = 'uSUl8Wf4e4hFEIDCNbfVqn2bVy22';

function getFirebaseToken() {
  try {
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

function randomBetween(min, max) { return Math.random() * (max - min) + min; }
function randomDate(daysBack) { return new Date(Date.now() - Math.random() * daysBack * 86400000); }
function pickRandom(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

const cryptos = [
  { id: 'bitcoin', name: 'Bitcoin', symbol: 'btc', image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png', price: 67500 },
  { id: 'ethereum', name: 'Ethereum', symbol: 'eth', image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png', price: 3450 },
  { id: 'solana', name: 'Solana', symbol: 'sol', image: 'https://assets.coingecko.com/coins/images/4128/large/solana.png', price: 145 },
  { id: 'cardano', name: 'Cardano', symbol: 'ada', image: 'https://assets.coingecko.com/coins/images/975/large/cardano.png', price: 0.45 },
  { id: 'ripple', name: 'XRP', symbol: 'xrp', image: 'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png', price: 0.52 },
];

async function seed() {
  const refreshToken = getFirebaseToken();
  if (!refreshToken) {
    console.error('No se encontro token de Firebase. Ejecuta: npx firebase login');
    process.exit(1);
  }

  console.log('Obteniendo access token...');
  const accessToken = await getAccessTokenFromRefresh(refreshToken);
  console.log('Token obtenido. Creando datos para usuario real:', REAL_UID);

  const writes = [];
  const docBase = `projects/${PROJECT_ID}/databases/(default)/documents`;

  // Wallet con 4 criptos
  const userCryptos = cryptos.slice(0, 4); // BTC, ETH, SOL, ADA
  const walletItems = userCryptos.map(c => ({
    currencyId: c.id,
    name: c.name,
    symbol: c.symbol,
    image: c.image,
    amount: parseFloat(randomBetween(0.01, c.price > 1000 ? 1.5 : 300).toFixed(8)),
    averageBuyPrice: parseFloat((c.price * randomBetween(0.85, 1.1)).toFixed(2)),
  }));

  const usdBalance = parseFloat(randomBetween(500, 8000).toFixed(2));

  // Wallet document
  writes.push({
    update: {
      name: `${docBase}/users/${REAL_UID}/data/wallet`,
      ...toFirestoreDoc({ items: walletItems, usdBalance }),
    },
  });

  // 10 transacciones variadas en los ultimos 30 dias
  for (let t = 0; t < 10; t++) {
    const crypto = pickRandom(userCryptos);
    const isBuy = Math.random() > 0.35;
    const amount = parseFloat(randomBetween(0.005, crypto.price > 1000 ? 0.5 : 100).toFixed(8));
    const pricePerUnit = parseFloat((crypto.price * randomBetween(0.9, 1.1)).toFixed(2));
    const totalValue = parseFloat((amount * pricePerUnit).toFixed(2));
    const txDate = randomDate(30);
    const txId = `${REAL_UID}_tx_${String(t + 1).padStart(3, '0')}`;

    writes.push({
      update: {
        name: `${docBase}/users/${REAL_UID}/transactions/${txId}`,
        ...toFirestoreDoc({
          id: txId,
          currencyId: crypto.id,
          currencyName: crypto.name,
          currencySymbol: crypto.symbol,
          currencyImage: crypto.image,
          type: isBuy ? 'buy' : 'sell',
          amount,
          pricePerUnit,
          totalValue,
          timestamp: txDate.toISOString(),
        }),
      },
    });
  }

  await commitBatch(accessToken, writes);
  console.log(`\nListo! ${writes.length} documentos creados para el usuario ${REAL_UID}:`);
  console.log(`  - 1 wallet con ${walletItems.length} criptos (saldo USD: $${usdBalance})`);
  console.log(`  - 10 transacciones de los ultimos 30 dias`);
}

seed().catch(console.error);
