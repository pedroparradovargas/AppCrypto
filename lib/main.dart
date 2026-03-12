import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/crypto_provider.dart';
import 'providers/blockchain_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/history_screen.dart';
import 'screens/create_wallet_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/walletconnect_screen.dart';
import 'screens/login_register_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/responsive.dart';

bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (con try/catch por si no esta configurado aun)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase no configurado: $e');
    firebaseInitialized = false;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CryptoProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BlockchainProvider(),
        ),
      ],
      child: const CryptoExchangeApp(),
    ),
  );
}

class CryptoExchangeApp extends StatelessWidget {
  const CryptoExchangeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoExchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Gate de autenticacion: Firebase Login -> PIN local -> App
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Cargando estado inicial
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        // Paso 1: Verificar autenticacion Firebase
        if (!auth.isFirebaseAuthenticated) {
          return const LoginRegisterScreen();
        }

        // Paso 2: Verificar PIN local (si esta habilitado)
        if (auth.requiresAuth && !auth.isAuthenticated) {
          return const PinLockScreen();
        }

        // Paso 3: App principal
        return const MainNavigation();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _providersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providersInitialized) {
      _providersInitialized = true;
      // Inicializar providers pesados después de que la UI ya se pintó
      Future.microtask(() {
        context.read<CryptoProvider>().initialize();
        context.read<BlockchainProvider>().initialize();
      });
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const WalletScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(8),
              vertical: Responsive.h(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.trending_up, 'Market')),
                Expanded(child: _buildNavItem(1, Icons.account_balance_wallet, 'Wallet')),
                Expanded(child: _buildNavItem(2, Icons.receipt_long, 'History')),
                Expanded(child: _buildNavItem(3, Icons.person, 'Perfil')),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.blueAccent : Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(8),
          vertical: Responsive.h(10),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: Responsive.sp(24)),
            SizedBox(height: Responsive.h(4)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: Responsive.sp(12),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(Responsive.w(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Responsive.w(40),
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: Responsive.h(20)),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: Responsive.sp(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.h(20)),
              _buildActionTile(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Create Blockchain Wallet',
                subtitle: 'Generate a new crypto wallet',
                color: const Color(0xFF1E88E5),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateWalletScreen()));
                },
              ),
              SizedBox(height: Responsive.h(12)),
              _buildActionTile(
                context,
                icon: Icons.payment,
                title: 'Add Funds',
                subtitle: 'Deposit money to your account',
                color: const Color(0xFF43A047),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen()));
                },
              ),
              SizedBox(height: Responsive.h(12)),
              _buildActionTile(
                context,
                icon: Icons.security,
                title: 'Seguridad',
                subtitle: 'Configura PIN, biometria y 2FA',
                color: const Color(0xFF7C4DFF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
                },
              ),
              SizedBox(height: Responsive.h(12)),
              _buildActionTile(
                context,
                icon: Icons.link,
                title: 'WalletConnect',
                subtitle: 'Conecta billetera externa',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WalletConnectScreen()));
                },
              ),
              SizedBox(height: Responsive.h(12)),
              _buildActionTile(
                context,
                icon: Icons.logout,
                title: 'Cerrar Sesion',
                subtitle: 'Salir de tu cuenta',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthProvider>().signOut();
                },
              ),
              SizedBox(height: Responsive.h(20)),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(Responsive.w(10)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: Responsive.sp(14),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey,
          size: Responsive.sp(16)),
    );
  }
}
