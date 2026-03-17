import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'pin_lock_screen.dart';

/// Security settings screen - PIN, biometric, 2FA configuration
class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Seguridad'),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return ListView(
            padding: EdgeInsets.all(Responsive.w(16)),
            children: [
              // Security header
              Container(
                padding: EdgeInsets.all(Responsive.w(20)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.w(12)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: Responsive.sp(32),
                      ),
                    ),
                    SizedBox(width: Responsive.w(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proteccion de Cuenta',
                            style: TextStyle(
                              fontSize: Responsive.sp(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: Responsive.h(4)),
                          Text(
                            _getSecurityLevel(auth),
                            style: TextStyle(
                              fontSize: Responsive.sp(14),
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(24)),

              // PIN Section
              _buildSectionTitle('Acceso con PIN'),
              SizedBox(height: Responsive.h(8)),
              _buildSettingCard(
                context,
                icon: Icons.pin_outlined,
                title: 'PIN de Acceso',
                subtitle: auth.isPinEnabled
                    ? 'PIN configurado'
                    : 'Protege tu app con un PIN de 4 digitos',
                trailing: Switch(
                  value: auth.isPinEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (enabled) {
                    if (enabled) {
                      _setupPin(context);
                    } else {
                      _removePin(context, auth);
                    }
                  },
                ),
              ),
              if (auth.isPinEnabled) ...[
                SizedBox(height: Responsive.h(8)),
                _buildSettingCard(
                  context,
                  icon: Icons.edit,
                  title: 'Cambiar PIN',
                  subtitle: 'Actualiza tu PIN de acceso',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: Responsive.sp(16),
                  ),
                  onTap: () => _changePin(context),
                ),
              ],
              SizedBox(height: Responsive.h(24)),

              // Biometric Section
              _buildSectionTitle('Autenticacion Biometrica'),
              SizedBox(height: Responsive.h(8)),
              _buildSettingCard(
                context,
                icon: Icons.fingerprint,
                title: 'Huella Digital / Face ID',
                subtitle: auth.isBiometricEnabled
                    ? 'Activado'
                    : 'Usa biometria para acceder rapidamente',
                trailing: Switch(
                  value: auth.isBiometricEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: auth.isPinEnabled
                      ? (enabled) => auth.toggleBiometric(enabled)
                      : null,
                ),
              ),
              if (!auth.isPinEnabled)
                Padding(
                  padding: EdgeInsets.only(left: Responsive.w(16), top: Responsive.h(4)),
                  child: Text(
                    'Configura un PIN primero para habilitar biometria',
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              SizedBox(height: Responsive.h(24)),

              // 2FA Section
              _buildSectionTitle('Autenticacion de Dos Factores (2FA)'),
              SizedBox(height: Responsive.h(8)),
              _buildSettingCard(
                context,
                icon: Icons.security,
                title: 'Google Authenticator / TOTP',
                subtitle: auth.is2FAEnabled
                    ? '2FA activado'
                    : 'Agrega una capa extra de seguridad',
                trailing: Switch(
                  value: auth.is2FAEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (enabled) {
                    if (enabled) {
                      _setup2FA(context, auth);
                    } else {
                      _disable2FA(context, auth);
                    }
                  },
                ),
              ),
              if (auth.is2FAEnabled) ...[
                SizedBox(height: Responsive.h(8)),
                _buildSettingCard(
                  context,
                  icon: Icons.qr_code,
                  title: 'Ver Clave Secreta',
                  subtitle: 'Muestra la clave para tu app de autenticacion',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: Responsive.sp(16),
                  ),
                  onTap: () => _show2FASecret(context, auth),
                ),
              ],
              SizedBox(height: Responsive.h(24)),

              // Lock app button
              if (auth.isPinEnabled) ...[
                _buildSectionTitle('Acciones'),
                SizedBox(height: Responsive.h(8)),
                _buildSettingCard(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Bloquear App',
                  subtitle: 'Bloquea la app inmediatamente',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: Responsive.sp(16),
                  ),
                  onTap: () {
                    auth.lock();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
              SizedBox(height: Responsive.h(40)),
            ],
          );
        },
      ),
    );
  }

  String _getSecurityLevel(AuthProvider auth) {
    int level = 0;
    if (auth.isPinEnabled) level++;
    if (auth.isBiometricEnabled) level++;
    if (auth.is2FAEnabled) level++;

    switch (level) {
      case 0:
        return 'Nivel: Basico - Configura seguridad adicional';
      case 1:
        return 'Nivel: Medio - Buena proteccion';
      case 2:
        return 'Nivel: Alto - Muy buena proteccion';
      case 3:
        return 'Nivel: Maximo - Proteccion completa';
      default:
        return 'Nivel: Basico';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: Responsive.sp(16),
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(Responsive.w(8)),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: Responsive.sp(24)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: Responsive.sp(14),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(12)),
        ),
        trailing: trailing,
      ),
    );
  }

  void _setupPin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PinLockScreen(isSetup: true),
      ),
    );
  }

  void _removePin(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Desactivar PIN',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu PIN actual para desactivarlo',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '****',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              auth.removePin(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _changePin(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Cambiar PIN',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'PIN actual',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Nuevo PIN',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await auth.changePin(
                oldPinController.text,
                newPinController.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'PIN actualizado correctamente'
                          : 'PIN actual incorrecto',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            child: const Text(
              'Cambiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _setup2FA(BuildContext context, AuthProvider auth) async {
    final secret = await auth.enable2FA();
    if (secret != null && context.mounted) {
      _show2FASecretDialog(context, secret);
    }
  }

  void _disable2FA(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Desactivar 2FA',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esto reducira la seguridad de tu cuenta. Estas seguro?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              auth.disable2FA();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _show2FASecret(BuildContext context, AuthProvider auth) async {
    final secret = await auth.get2FASecret();
    if (secret != null && context.mounted) {
      _show2FASecretDialog(context, secret);
    }
  }

  void _show2FASecretDialog(BuildContext context, String secret) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Clave Secreta 2FA',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa esta clave en tu app de autenticacion (Google Authenticator, Authy, etc.):',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: Responsive.h(16)),
            Container(
              padding: EdgeInsets.all(Responsive.w(16)),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      secret,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: Responsive.sp(16),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: secret));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clave copiada al portapapeles'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(12)),
            Text(
              'Guarda esta clave en un lugar seguro. La necesitaras si pierdes acceso a tu app de autenticacion.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: Responsive.sp(12)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
