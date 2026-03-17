import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';

enum AuthMode { login, register, resetPassword }

/// Pantalla de Login / Registro / Recuperar contraseña
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({Key? key}) : super(key: key);

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AuthMode _authMode = AuthMode.login;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _enableBiometric = false;
  bool _resetEmailSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _authMode = AuthMode.values[_tabController.index];
        _resetEmailSent = false;
        context.read<AuthProvider>().clearError();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.w(24)),
          child: Column(
            children: [
              SizedBox(height: Responsive.h(40)),
              _buildLogo(),
              SizedBox(height: Responsive.h(32)),
              _buildTabBar(),
              SizedBox(height: Responsive.h(24)),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(20)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF7C4DFF)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.currency_bitcoin,
            size: Responsive.sp(48),
            color: Colors.white,
          ),
        ),
        SizedBox(height: Responsive.h(16)),
        Text(
          'CryptoExchange',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.sp(28),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Responsive.h(4)),
        Text(
          'Tu plataforma de trading segura',
          style: TextStyle(
            color: Colors.grey,
            fontSize: Responsive.sp(14),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontSize: Responsive.sp(13), fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: Responsive.sp(12)),
        tabs: const [
          Tab(text: 'Iniciar Sesion'),
          Tab(text: 'Registrarse'),
          Tab(text: 'Recuperar'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (auth.error != null) ...[
              Container(
                padding: EdgeInsets.all(Responsive.w(12)),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.redAccent,
                        size: Responsive.sp(20)),
                    SizedBox(width: Responsive.w(8)),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: Responsive.sp(13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(16)),
            ],

            // Form fields based on mode
            if (_authMode == AuthMode.login) _buildLoginForm(auth),
            if (_authMode == AuthMode.register) _buildRegisterForm(auth),
            if (_authMode == AuthMode.resetPassword) _buildResetForm(auth),
          ],
        );
      },
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outlined,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: Responsive.sp(20),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: Responsive.h(24)),
        _buildPrimaryButton(
          label: 'Iniciar Sesion',
          isLoading: auth.isLoading,
          onPressed: () => _handleLogin(auth),
        ),
        SizedBox(height: Responsive.h(16)),
        TextButton(
          onPressed: () {
            _tabController.animateTo(2);
          },
          child: Text(
            'Olvidaste tu contraseña?',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: Responsive.sp(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _displayNameController,
          label: 'Nombre completo',
          icon: Icons.person_outlined,
        ),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outlined,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: Responsive.sp(20),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: Responsive.h(4)),
        _buildPasswordStrength(),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outlined,
          obscure: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: Responsive.sp(20),
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        SizedBox(height: Responsive.h(16)),
        // Biometric toggle
        Container(
          padding: EdgeInsets.all(Responsive.w(16)),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blueAccent,
                  size: Responsive.sp(28)),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrar huella digital',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Accede rapidamente con tu huella',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: Responsive.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableBiometric,
                activeColor: Colors.blueAccent,
                onChanged: (v) => setState(() => _enableBiometric = v),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(24)),
        _buildPrimaryButton(
          label: 'Crear Cuenta',
          isLoading: auth.isLoading,
          onPressed: () => _handleRegister(auth),
        ),
      ],
    );
  }

  Widget _buildResetForm(AuthProvider auth) {
    if (_resetEmailSent) {
      return Container(
        padding: EdgeInsets.all(Responsive.w(24)),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.mark_email_read, color: Colors.greenAccent,
                size: Responsive.sp(48)),
            SizedBox(height: Responsive.h(16)),
            Text(
              'Email enviado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.sp(20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: Responsive.sp(14),
              ),
            ),
            SizedBox(height: Responsive.h(24)),
            TextButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: Text(
                'Volver a Iniciar Sesion',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: Responsive.sp(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16)),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.lock_reset, color: Colors.blueAccent,
                  size: Responsive.sp(40)),
              SizedBox(height: Responsive.h(12)),
              Text(
                'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: Responsive.sp(14),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: Responsive.h(24)),
        _buildPrimaryButton(
          label: 'Enviar Enlace',
          isLoading: auth.isLoading,
          onPressed: () => _handleReset(auth),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: Colors.white, fontSize: Responsive.sp(16)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: Responsive.sp(22)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.w(16),
          vertical: Responsive.h(16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: Responsive.h(16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: isLoading
          ? SizedBox(
              height: Responsive.sp(20),
              width: Responsive.sp(20),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: Responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    Color color;
    String label;
    if (strength <= 1) {
      color = Colors.redAccent;
      label = 'Debil';
    } else if (strength <= 3) {
      color = Colors.orangeAccent;
      label = 'Media';
    } else {
      color = Colors.greenAccent;
      label = 'Fuerte';
    }

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.h(4)),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 5,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  color: color,
                  minHeight: 4,
                ),
              ),
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              label,
              style: TextStyle(color: color, fontSize: Responsive.sp(12)),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== HANDLERS ====================

  Future<void> _handleLogin(AuthProvider auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      auth.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    await auth.signInWithEmail(email: email, password: password);
  }

  Future<void> _handleRegister(AuthProvider auth) async {
    final name = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    final success = await auth.registerWithEmail(
      email: email,
      password: password,
      displayName: name,
    );

    if (success && _enableBiometric) {
      await auth.registerBiometric();
    }
  }

  Future<void> _handleReset(AuthProvider auth) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu email')),
      );
      return;
    }

    final success = await auth.sendPasswordReset(email);
    if (success) {
      setState(() {
        _resetEmailSent = true;
      });
    }
  }
}
