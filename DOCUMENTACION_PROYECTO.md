# CryptoExchange - Documentacion del Proyecto

## 1. Descripcion General

**CryptoExchange** es una aplicacion movil desarrollada en **Flutter** que funciona como una plataforma de trading de criptomonedas y gestion de billeteras blockchain. La aplicacion combina dos sistemas principales:

- **Sistema de Trading (Demo):** Permite comprar y vender criptomonedas con un balance simulado de $10,000 USD, utilizando precios en tiempo real de la API de CoinGecko.
- **Sistema de Billeteras Blockchain:** Permite generar, importar y conectar billeteras blockchain con soporte para multiples redes (Ethereum, Polygon, Binance Smart Chain).

---

## 2. Tecnologias Utilizadas

| Tecnologia | Version | Proposito |
|------------|---------|-----------|
| **Flutter** | SDK | Framework principal de desarrollo multiplataforma |
| **Dart** | 3.0.0+ | Lenguaje de programacion |
| **Provider** | ^6.1.1 | Gestion de estado (patron ChangeNotifier) |
| **HTTP** | ^1.2.0 | Peticiones HTTP a la API de CoinGecko |
| **fl_chart** | ^0.69.0 | Graficos de precios (lineas) |
| **shared_preferences** | ^2.2.2 | Persistencia local de datos de trading |
| **flutter_secure_storage** | ^9.0.0 | Almacenamiento encriptado de billeteras |
| **intl** | ^0.19.0 | Formateo de fechas y numeros |
| **crypto** | ^3.0.3 | Utilidades criptograficas (hashing) |

---

## 3. Arquitectura del Proyecto

### 3.1 Estructura de Directorios

```
lib/
├── main.dart                          # Punto de entrada y navegacion
├── models/                            # Modelos de datos
│   ├── blockchain_wallet.dart         # Modelos de billetera blockchain
│   ├── currency.dart                  # Modelo de criptomoneda
│   ├── transaction.dart               # Modelo de transaccion de trading
│   └── wallet.dart                    # Modelo de billetera de trading
├── providers/                         # Gestion de estado
│   ├── crypto_provider.dart           # Estado del sistema de trading
│   └── blockchain_provider.dart       # Estado de billeteras blockchain
├── services/                          # Logica de negocio y APIs
│   ├── crypto_service.dart            # Integracion con CoinGecko API
│   ├── blockchain_service.dart        # Generacion y gestion de billeteras
│   └── payment_service.dart           # Procesamiento de pagos (demo)
└── screens/                           # Pantallas de la interfaz
    ├── home_screen.dart               # Vista del mercado
    ├── wallet_screen.dart             # Billeteras de trading y blockchain
    ├── detail_screen.dart             # Detalle de criptomoneda con grafico
    ├── history_screen.dart            # Historial de transacciones
    ├── create_wallet_screen.dart      # Creacion de billeteras blockchain
    └── payment_screen.dart            # Gestion de pagos y depositos
```

### 3.2 Patron de Arquitectura

La aplicacion sigue el patron **Provider** para la gestion de estado, con una separacion clara en tres capas:

```
Pantallas (UI) → Providers (Estado) → Servicios (Logica de negocio / APIs)
                                           ↓
                                   Almacenamiento local
```

- **Pantallas:** Se encargan unicamente de la presentacion visual.
- **Providers:** Gestionan el estado de la aplicacion usando `ChangeNotifier`.
- **Servicios:** Contienen la logica de negocio, llamadas a APIs y operaciones criptograficas.

---

## 4. Pantallas de la Aplicacion

### 4.1 Pantalla Principal (HomeScreen)
- Muestra las **100 principales criptomonedas** por capitalizacion de mercado.
- Incluye barra de busqueda por nombre o simbolo.
- Muestra precio actual, cambio en 24h y mini-grafico (sparkline).
- Boton flotante para agregar fondos rapidamente.

### 4.2 Pantalla de Detalle (DetailScreen)
- Informacion detallada de una criptomoneda seleccionada.
- **Grafico de precios** interactivo con periodos seleccionables: 1 dia, 1 semana, 1 mes, 3 meses.
- Interfaz para comprar y vender con validacion de saldo.
- Estadisticas de tenencias actuales del usuario.

### 4.3 Pantalla de Billetera (WalletScreen)
- **Dos pestanas:**
  - **Trading:** Resumen del portafolio (balance USD, valor total, ganancias/perdidas).
  - **Blockchain:** Lista de billeteras creadas con direccion, red y balance.

### 4.4 Pantalla de Historial (HistoryScreen)
- Registro de todas las transacciones de compra/venta realizadas.
- Muestra tipo de operacion, cantidad, precio, fecha y ganancia/perdida.

### 4.5 Pantalla de Crear Billetera (CreateWalletScreen)
- **Tres opciones:**
  - Generar nueva billetera (con frase mnemonica BIP-39).
  - Importar billetera existente desde frase de recuperacion.
  - Conectar billetera externa (MetaMask, Trust Wallet).
- Seleccion de red: Ethereum, Polygon, Binance Smart Chain.

### 4.6 Pantalla de Pagos (PaymentScreen)
- Agregar tarjetas de pago con validacion (algoritmo de Luhn).
- Gestionar tarjetas guardadas.
- Procesar depositos y retiros (simulado).

---

## 5. Modelos de Datos

### 5.1 Sistema de Trading

| Modelo | Descripcion | Campos principales |
|--------|-------------|-------------------|
| **Currency** | Datos de una criptomoneda | id, nombre, simbolo, precio, market cap, cambio 24h, sparkline |
| **Transaction** | Transaccion de compra/venta | id, tipo (buy/sell), cantidad, precio, fecha, ganancia/perdida |
| **WalletItem** | Tenencia de una cripto | moneda, cantidad, precio promedio de compra |
| **Wallet** | Portafolio del usuario | lista de items, balance USD, valor total |

### 5.2 Sistema Blockchain

| Modelo | Descripcion | Campos principales |
|--------|-------------|-------------------|
| **BlockchainWallet** | Billetera real | direccion, clave privada, mnemonica, red, balance, respaldo |
| **PaymentMethod** | Tarjeta de pago | ultimos 4 digitos, marca, tipo |
| **BlockchainTransaction** | Transaccion on-chain | hash, direccion origen/destino, monto, estado, confirmaciones |

### 5.3 Enumeraciones

- **TransactionType:** `buy`, `sell`
- **BlockchainNetwork:** `ethereum`, `polygon`, `binancesmartchain` (con nombres, simbolos y URLs RPC)

---

## 6. Servicios

### 6.1 CryptoService (API de CoinGecko)
Servicio que consume la API publica de CoinGecko para obtener datos del mercado en tiempo real.

**Endpoints utilizados:**
- `GET /coins/markets` — Lista de criptomonedas ordenadas por market cap, con datos de sparkline.
- `GET /coins/{id}/market_chart` — Historial de precios para graficos (7, 30, 90 dias).

**Caracteristicas:**
- No requiere autenticacion (API publica y gratuita).
- Datos en tiempo real actualizados periodicamente.
- Soporte para busqueda y filtrado.

### 6.2 BlockchainService (Gestion de Billeteras)
Servicio para la creacion y gestion de billeteras blockchain.

**Funcionalidades:**
- **Generacion de billeteras:** Crea frases mnemonicas BIP-39 de 12 palabras seleccionadas del wordlist estandar de 2048 palabras.
- **Importacion:** Permite restaurar billeteras desde frases de recuperacion.
- **Conexion externa:** Conecta billeteras existentes en modo solo lectura (solo direccion, sin clave privada).
- **Soporte multi-red:** Ethereum, Polygon, Binance Smart Chain.

> **Nota:** La generacion de billeteras es una implementacion demo/simulada. Para produccion se requieren las librerias `web3dart`, `bip39` y `bip32`.

### 6.3 PaymentService (Procesamiento de Pagos)
Servicio de validacion y procesamiento de metodos de pago.

**Validaciones implementadas:**
- **Algoritmo de Luhn:** Validacion estandar de numeros de tarjeta.
- **Deteccion de marca:** Visa, Mastercard, Amex, Discover.
- **Validacion de expiracion:** Verifica que la tarjeta no este vencida.
- **Validacion de CVC:** Formato de 3-4 digitos.

> **Nota:** El procesamiento de pagos es simulado (demo). No se conecta a pasarelas de pago reales.

---

## 7. Gestion de Estado (Providers)

### 7.1 CryptoProvider
Gestiona todo el estado del sistema de trading.

**Funciones principales:**
| Metodo | Descripcion |
|--------|-------------|
| `fetchCurrencies()` | Carga las 100 principales criptomonedas desde la API |
| `buyCurrency()` | Simula la compra (valida saldo, crea transaccion, actualiza portafolio) |
| `sellCurrency()` | Simula la venta (valida tenencias, actualiza balance) |
| `searchCurrencies()` | Busqueda en tiempo real por nombre/simbolo |
| `loadHistoricalPrices()` | Obtiene datos de precios de 7/30/90 dias |
| `calculateProfitLoss()` | Calcula ganancias/perdidas no realizadas |

**Persistencia:** SharedPreferences (datos de billetera y transacciones en formato JSON).

### 7.2 BlockchainProvider
Gestiona el estado de billeteras blockchain y pagos.

**Funciones principales:**
| Metodo | Descripcion |
|--------|-------------|
| `generateWallet()` | Crea nueva billetera con mnemonica |
| `importWallet()` | Importa billetera desde frase de recuperacion |
| `connectExternalWallet()` | Vincula billetera externa (solo lectura) |
| `refreshWalletBalance()` | Actualiza balance de billetera |
| `addPaymentMethod()` | Agrega tarjeta de credito |
| `deposit()` / `withdraw()` | Simula deposito/retiro |
| `sendTransaction()` | Simula transaccion blockchain |

**Persistencia:** FlutterSecureStorage (almacenamiento encriptado).

---

## 8. Flujos Principales

### 8.1 Flujo de Compra de Criptomoneda
```
1. Usuario navega al HomeScreen
2. Selecciona una criptomoneda → DetailScreen
3. Ingresa cantidad a comprar
4. CryptoProvider.buyCurrency():
   a. Valida que el saldo USD sea suficiente
   b. Descuenta el monto del balance
   c. Agrega/actualiza el WalletItem en el portafolio
   d. Registra la Transaction en el historial
   e. Persiste los cambios en SharedPreferences
5. UI se actualiza automaticamente via ChangeNotifier
```

### 8.2 Flujo de Generacion de Billetera
```
1. Usuario navega a WalletScreen → pestana Blockchain
2. Presiona "Crear Billetera" → CreateWalletScreen
3. Selecciona red (Ethereum/Polygon/BSC)
4. Elige "Generar Nueva Billetera"
5. BlockchainService.generateWallet():
   a. Genera 12 palabras mnemonicas BIP-39
   b. Crea direccion hexadecimal desde la mnemonica
   c. Genera representacion de clave privada
6. Billetera se encripta y guarda en FlutterSecureStorage
7. Se muestra dialogo con la frase de recuperacion
8. Usuario debe respaldar la frase mnemonica
```

### 8.3 Flujo de Importacion de Billetera
```
1. Usuario accede a CreateWalletScreen
2. Selecciona "Importar Billetera"
3. Ingresa frase mnemonica de 12-24 palabras
4. BlockchainService.importFromMnemonic():
   a. Valida formato de la mnemonica
   b. Deriva direccion desde la frase
   c. Genera clave privada
5. Billetera se guarda de forma segura
6. Confirmacion mostrada al usuario
```

---

## 9. Seguridad

| Caracteristica | Implementacion |
|----------------|---------------|
| **Almacenamiento seguro** | FlutterSecureStorage (AES-256) para billeteras y claves privadas |
| **Encriptacion por plataforma** | Android: EncryptedSharedPreferences, iOS: Keychain, Windows: DPAPI |
| **Validacion de tarjetas** | Algoritmo de Luhn (estandar de la industria) |
| **Visibilidad de mnemonica** | Toggle para mostrar/ocultar frase de recuperacion |
| **Confirmacion de eliminacion** | Dialogo de confirmacion antes de eliminar billeteras |
| **Modo solo lectura** | Billeteras externas conectadas sin clave privada |

---

## 10. Interfaz de Usuario

- **Tema:** Modo oscuro (Material Dark Theme).
- **Navegacion:** Barra inferior con 3 pestanas (Mercado, Billetera, Historial).
- **Graficos:** Graficos de linea interactivos con la libreria fl_chart.
- **Componentes:** Bottom sheets modales, estados de carga con spinners, manejo de errores con boton de reintento, estados vacios con mensajes informativos.
- **Boton flotante:** Acceso rapido a acciones frecuentes.

---

## 11. Flujo de Datos

```
┌─────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACION                  │
│  HomeScreen | DetailScreen | WalletScreen | HistoryScreen│
│  CreateWalletScreen | PaymentScreen                      │
└──────────────────────┬──────────────────────────────────┘
                       │ Consumer<Provider>
┌──────────────────────▼──────────────────────────────────┐
│                   CAPA DE ESTADO                         │
│         CryptoProvider  |  BlockchainProvider            │
└──────────┬─────────────────────────────┬────────────────┘
           │                             │
┌──────────▼──────────┐    ┌─────────────▼────────────────┐
│  CAPA DE SERVICIOS  │    │     CAPA DE SERVICIOS        │
│   CryptoService     │    │  BlockchainService           │
│   (CoinGecko API)   │    │  PaymentService              │
└──────────┬──────────┘    └─────────────┬────────────────┘
           │                             │
┌──────────▼──────────┐    ┌─────────────▼────────────────┐
│  ALMACENAMIENTO     │    │    ALMACENAMIENTO SEGURO     │
│  SharedPreferences  │    │    FlutterSecureStorage      │
│  (Trading data)     │    │    (Wallets & keys)          │
└─────────────────────┘    └──────────────────────────────┘
```

---

## 12. API Externa

### CoinGecko API
- **Base URL:** `https://api.coingecko.com/api/v3`
- **Autenticacion:** No requerida (API publica)
- **Limite de peticiones:** Dependiente del plan gratuito de CoinGecko
- **Datos obtenidos:** Precios en tiempo real, capitalizacion de mercado, volumen 24h, cambio porcentual, datos historicos para graficos

---

## 13. Plataformas Soportadas

La aplicacion esta configurada para ejecutarse en:
- **Android** (principal)
- **iOS**
- **Web**
- **Windows**
- **Linux**
- **macOS**

---

## 14. Consideraciones para Produccion (IMPLEMENTADO)

Todas las consideraciones para produccion han sido implementadas:

### 14.1 Billeteras Reales (IMPLEMENTADO)
- **Archivo:** `lib/services/real_wallet_service.dart`
- Integra librerias `web3dart`, `bip39`, `bip32` para generacion real de billeteras HD
- Generacion de mnemonic BIP-39 con entropia criptografica segura (128/256 bits)
- Derivacion de claves privadas usando BIP-44 path (`m/44'/60'/0'/0/index`)
- Obtencion de direcciones Ethereum reales desde claves publicas
- Importacion desde mnemonic y clave privada
- Consulta de balances reales en la blockchain via Web3
- Envio de transacciones firmadas con clave privada
- Estimacion de gas y derivacion de multiples direcciones

### 14.2 Pagos Reales (IMPLEMENTADO)
- **Archivo:** `lib/services/stripe_payment_service.dart`
- **Stripe:** Integracion completa con la API de Stripe
  - Creacion de clientes (Customers)
  - Metodos de pago (PaymentMethods) con tokenizacion
  - PaymentIntents para procesamiento de pagos
  - SetupIntents para guardar tarjetas
  - Depositos, confirmaciones y reembolsos
- **MercadoPago:** Integracion para mercados latinoamericanos
  - Preferencias de pago con items y URLs de retorno
  - Consulta de estado de pagos
  - Soporte para COP, ARS, MXN y otras monedas

### 14.3 Backend (IMPLEMENTADO)
- **Archivo:** `lib/services/backend_service.dart`
- Cliente REST API completo para servidor backend
- **Autenticacion:** JWT con access/refresh tokens
  - Registro, login, logout
  - Renovacion automatica de tokens expirados
  - Almacenamiento seguro con FlutterSecureStorage
- **Gestion de usuarios:** Perfil, cambio de contrasena
- **Transacciones:** CRUD completo con paginacion y filtros
- **Billeteras:** Registro, listado y eliminacion en el backend
- **Portfolio:** Consulta de balances y historial
- Interceptor de autorizacion automatico con retry

### 14.4 Seguridad Adicional (IMPLEMENTADO)
- **Archivos:** `lib/services/security_service.dart`, `lib/providers/auth_provider.dart`, `lib/screens/pin_lock_screen.dart`, `lib/screens/security_settings_screen.dart`
- PIN de acceso de 4 digitos con hash SHA-256
- Autenticacion biometrica (huella digital / Face ID) con `local_auth`
- 2FA/TOTP con generacion de secreto para Google Authenticator
- Bloqueo por intentos fallidos (5 intentos, lockout de 5 minutos)
- Pantalla de configuracion de seguridad con niveles

### 14.5 WalletConnect (IMPLEMENTADO)
- **Archivos:** `lib/services/walletconnect_service.dart`, `lib/screens/walletconnect_screen.dart`
- Integracion con WalletConnect v2 usando `walletconnect_flutter_v2`
- Soporte para multiples redes: Ethereum, Polygon, BSC
- Generacion de URI de pairing para QR code
- Firma de mensajes personales (personal_sign)
- Envio de transacciones via billetera conectada
- Firma de datos tipados EIP-712
- Manejo de sesiones y reconexion automatica
- Pantalla UI completa con selector de red y billeteras compatibles
- Billeteras soportadas: MetaMask, Trust Wallet, Rainbow, Coinbase, Ledger, Phantom

### 14.6 Pruebas (IMPLEMENTADO)
- **Pruebas unitarias:** `test/models/` y `test/services/`
  - `blockchain_wallet_test.dart` - Modelos de billetera blockchain
  - `currency_test.dart` - Modelo de criptomoneda
  - `transaction_test.dart` - Modelo de transaccion
  - `wallet_test.dart` - Modelo de billetera de trading
  - `payment_service_test.dart` - Servicio de pagos demo
  - `security_service_test.dart` - Servicio de seguridad
  - `backend_service_test.dart` - Modelos del backend (AuthResponse, UserProfile, BackendTransaction)
  - `stripe_payment_service_test.dart` - Modelos de Stripe y MercadoPago
  - `real_wallet_service_test.dart` - Servicio de billeteras reales (BIP-39, BIP-32, derivacion)
- **Pruebas de interfaz (Widget tests):** `test/widget/`
  - `home_screen_test.dart` - Pantalla del mercado
  - `history_screen_test.dart` - Pantalla de historial
  - `security_settings_test.dart` - Pantalla de seguridad
- **Pruebas de integracion:** `integration_test/`
  - `app_test.dart` - Flujo completo de la app (inicio, navegacion, acciones rapidas)
