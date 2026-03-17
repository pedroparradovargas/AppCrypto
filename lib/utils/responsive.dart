import 'package:flutter/material.dart';

/// Utilidad para hacer la UI responsive.
/// Usa un ancho base de 375 (iPhone SE) como referencia.
class Responsive {
  static double _screenWidth = 375;
  static double _screenHeight = 667;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
  }

  /// Factor de escala horizontal
  static double get scaleW => _screenWidth / 375;

  /// Factor de escala vertical
  static double get scaleH => _screenHeight / 667;

  /// Escala un valor en base al ancho de pantalla
  static double w(double value) => value * scaleW;

  /// Escala un valor en base a la altura de pantalla
  static double h(double value) => value * scaleH;

  /// Escala font size (usa un factor moderado para no distorsionar mucho)
  static double sp(double value) {
    final scale = (_screenWidth / 375).clamp(0.8, 1.4);
    return value * scale;
  }

  /// Ancho de pantalla
  static double get width => _screenWidth;

  /// Alto de pantalla
  static double get height => _screenHeight;

  /// True si la pantalla es pequeña (< 360)
  static bool get isSmall => _screenWidth < 360;

  /// True si la pantalla es grande (tablet, > 600)
  static bool get isLarge => _screenWidth > 600;
}
