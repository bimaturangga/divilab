import 'package:flutter/material.dart';

/// Logo DiViLab. Gambar logo berlatar putih, jadi di Dark Mode
/// ditampilkan di atas badge putih (sesuai desain).
class DiviLogo extends StatelessWidget {
  const DiviLogo({super.key, this.width = 160});
  final double width;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset('assets/images/logo.png', width: width, fit: BoxFit.contain);
    if (Theme.of(context).brightness == Brightness.light) return img;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.1, vertical: width * 0.06),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: img,
    );
  }
}

/// Bendera Indonesia kecil (chip Bahasa).
class IndonesiaFlag extends StatelessWidget {
  const IndonesiaFlag({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x22000000)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5262E), Color(0xFFE5262E), Colors.white, Colors.white],
          stops: [0, 0.5, 0.5, 1],
        ),
      ),
    );
  }
}

/// Navigasi: ganti seluruh stack dengan [page].
void goRoot(BuildContext context, Widget page) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => page), (_) => false);
}

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));
