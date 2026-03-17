import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';

/// PIN lock screen - displayed when app requires authentication
class PinLockScreen extends StatefulWidget {
  final bool isSetup;

  const PinLockScreen({Key? key, this.isSetup = false}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    if (_isConfirming && _confirmPin.length >= 4) return;
    if (!_isConfirming && _pin.length >= 4) return;

    setState(() {
      _error = null;
      if (_isConfirming) {
        _confirmPin += number;
        if (_confirmPin.length == 4) {
          _handleConfirmPin();
        }
      } else {
        _pin += number;
        if (_pin.length == 4 && !widget.isSetup) {
          _handleVerifyPin();
        }
      }
    });
  }

  void _onDeleteTap() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _handleVerifyPin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.authenticateWithPin(_pin);

    if (!success) {
      _shakeController.forward(from: 0);
      setState(() {
        _error = authProvider.error;
        _pin = '';
      });
    }
  }

  void _handleConfirmPin() {
    if (_pin == _confirmPin) {
      final authProvider = context.read<AuthProvider>();
      authProvider.setupPin(_pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _error = 'Los PINs no coinciden. Intenta de nuevo.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  String get _currentPin => _isConfirming ? _confirmPin : _pin;

  String get _title {
    if (widget.isSetup) {
      return _isConfirming ? 'Confirmar PIN' : 'Crear PIN';
    }
    return 'Ingresa tu PIN';
  }

  String get _subtitle {
    if (widget.isSetup) {
      return _isConfirming
          ? 'Ingresa el PIN nuevamente'
          : 'Configura un PIN de 4 digitos';
    }
    return 'Ingresa tu PIN para acceder';
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final buttonSize = Responsive.w(72).clamp(56.0, 90.0);
    final dotSize = Responsive.w(20).clamp(16.0, 28.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 16),
                    // Top section
                    Column(
                      children: [
                        // Lock icon
                        Container(
                          padding: EdgeInsets.all(Responsive.w(20)),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            size: Responsive.sp(48),
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: Responsive.h(24)),
                        // Title
                        Text(
                          _title,
                          style: TextStyle(
                            fontSize: Responsive.sp(24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: Responsive.h(8)),
                        Text(
                          _subtitle,
                          style: TextStyle(
                            fontSize: Responsive.sp(14),
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: Responsive.h(32)),
                        // PIN dots
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _currentPin.length;
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: Responsive.w(10)),
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled ? Colors.blueAccent : Colors.transparent,
                                  border: Border.all(
                                    color: isFilled ? Colors.blueAccent : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Error message
                        if (_error != null) ...[
                          SizedBox(height: Responsive.h(16)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.w(40)),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: Responsive.sp(14),
                              ),
                            ),
                          ),
                        ],
                        // Setup flow: submit button
                        if (widget.isSetup && _pin.length == 4 && !_isConfirming) ...[
                          SizedBox(height: Responsive.h(24)),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isConfirming = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.w(48),
                                vertical: Responsive.h(12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: Responsive.sp(16),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Number pad
                    Padding(
                      padding: EdgeInsets.only(top: Responsive.h(16)),
                      child: _buildNumberPad(buttonSize),
                    ),
                    SizedBox(height: Responsive.h(20)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberPad(double buttonSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(40)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1', buttonSize),
              _buildNumberButton('2', buttonSize),
              _buildNumberButton('3', buttonSize),
            ],
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4', buttonSize),
              _buildNumberButton('5', buttonSize),
              _buildNumberButton('6', buttonSize),
            ],
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7', buttonSize),
              _buildNumberButton('8', buttonSize),
              _buildNumberButton('9', buttonSize),
            ],
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: buttonSize, height: buttonSize),
              _buildNumberButton('0', buttonSize),
              _buildDeleteButton(buttonSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number, double size) {
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: Responsive.sp(28),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(double size) {
    return GestureDetector(
      onTap: _onDeleteTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.grey,
            size: Responsive.sp(24),
          ),
        ),
      ),
    );
  }
}
