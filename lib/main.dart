import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/assistant_service.dart';
import 'data/services/device_simulator.dart';
import 'data/services/dummyjson_service.dart';
import 'state/app_state.dart';
import 'state/health_store.dart';
import 'state/ui_controllers.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, HealthStore>(
          create: (_) => HealthStore(),
          update: (_, app, store) => (store ?? HealthStore())..bind(app.user?.id, app.activeProfile?.id),
        ),
        ChangeNotifierProvider(create: (_) => ShellController()),
        ChangeNotifierProvider(create: (_) => DeviceController()),
        Provider(create: (_) => DummyJsonService()),
        Provider(create: (_) => AssistantService()),
        Provider(create: (_) => DeviceSimulator()),
      ],
      child: const DiViLabApp(),
    ),
  );
}

class DiViLabApp extends StatelessWidget {
  const DiViLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'DiViLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}
