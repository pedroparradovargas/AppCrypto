import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'security_settings_screen.dart';

/// Pantalla de perfil del usuario
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final profile = auth.userProfile;
          final firebaseUser = auth.firebaseUser;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.w(20)),
              child: Column(
                children: [
                  SizedBox(height: Responsive.h(20)),
                  // Header
                  Text(
                    'Mi Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.sp(24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.h(24)),

                  // Avatar y nombre
                  _buildAvatar(profile?.displayName ?? firebaseUser?.displayName ?? 'Usuario'),
                  SizedBox(height: Responsive.h(16)),
                  Text(
                    profile?.displayName ?? firebaseUser?.displayName ?? 'Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.sp(22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    profile?.email ?? firebaseUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: Responsive.sp(14),
                    ),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  // Badge verificado
                  if (firebaseUser?.emailVerified == true)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(12),
                        vertical: Responsive.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.greenAccent,
                              size: Responsive.sp(16)),
                          SizedBox(width: Responsive.w(4)),
                          Text(
                            'Email verificado',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: Responsive.sp(12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: Responsive.h(32)),

                  // Informacion de la cuenta
                  _buildSectionTitle('Informacion de la cuenta'),
                  SizedBox(height: Responsive.h(12)),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.person_outlined,
                      'Nombre',
                      profile?.displayName ?? firebaseUser?.displayName ?? 'Sin nombre',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      profile?.email ?? firebaseUser?.email ?? '',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Miembro desde',
                      profile != null
                          ? DateFormat('dd MMM yyyy').format(profile.createdAt)
                          : 'N/A',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.access_time,
                      'Ultimo acceso',
                      profile != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(profile.lastLogin)
                          : 'N/A',
                    ),
                  ]),

                  SizedBox(height: Responsive.h(24)),

                  // Seguridad
                  _buildSectionTitle('Seguridad'),
                  SizedBox(height: Responsive.h(12)),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.fingerprint,
                      'Huella digital',
                      auth.isBiometricEnabled ? 'Activada' : 'Desactivada',
                      valueColor: auth.isBiometricEnabled
                          ? Colors.greenAccent
                          : Colors.grey,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.lock_outlined,
                      'PIN de seguridad',
                      auth.isPinEnabled ? 'Activado' : 'Desactivado',
                      valueColor: auth.isPinEnabled
                          ? Colors.greenAccent
                          : Colors.grey,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.security,
                      '2FA',
                      auth.is2FAEnabled ? 'Activado' : 'Desactivado',
                      valueColor: auth.is2FAEnabled
                          ? Colors.greenAccent
                          : Colors.grey,
                    ),
                  ]),

                  SizedBox(height: Responsive.h(24)),

                  // Acciones
                  _buildSectionTitle('Acciones'),
                  SizedBox(height: Responsive.h(12)),
                  _buildActionTile(
                    context,
                    icon: Icons.security,
                    title: 'Configurar seguridad',
                    subtitle: 'PIN, biometria y 2FA',
                    color: const Color(0xFF7C4DFF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecuritySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: Responsive.h(12)),
                  _buildActionTile(
                    context,
                    icon: Icons.logout,
                    title: 'Cerrar sesion',
                    subtitle: 'Salir de tu cuenta',
                    color: Colors.redAccent,
                    onTap: () => _confirmSignOut(context, auth),
                  ),

                  SizedBox(height: Responsive.h(40)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      width: Responsive.w(90),
      height: Responsive.w(90),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.sp(32),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey,
          fontSize: Responsive.sp(14),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(16),
          vertical: Responsive.h(8),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: Responsive.sp(20)),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: Responsive.sp(14),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: Responsive.sp(14),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.15),
      height: 1,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Responsive.w(16)),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.w(10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: Responsive.sp(24)),
            ),
            SizedBox(width: Responsive.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.sp(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: Responsive.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey,
                size: Responsive.sp(16)),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar sesion',
          style: TextStyle(color: Colors.white, fontSize: Responsive.sp(18)),
        ),
        content: Text(
          'Estas seguro que deseas cerrar sesion?',
          style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey, fontSize: Responsive.sp(14)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: Text(
              'Cerrar sesion',
              style: TextStyle(color: Colors.redAccent, fontSize: Responsive.sp(14)),
            ),
          ),
        ],
      ),
    );
  }
}
