import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/brand.dart';
import '../shell/main_shell.dart';

/// "Sinkronisasi Data" setelah login: mengunduh riwayat pengukuran.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) goRoot(context, const MainShell());
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const DiviLogo(width: 170),
              const SizedBox(height: 32),
              Text('Sinkronisasi Data', style: AppText.h2.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text('Sedang mengunduh riwayat pengukuran Anda', style: AppText.body.c(p.textSecondary)),
              const Spacer(flex: 3),
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Unduh Pengukuran', style: AppText.title.c(p.textPrimary))),
                        Text('${(_c.value * 100).round()}%', style: AppText.title.c(p.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 6,
                        backgroundColor: p.bgMuted,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
