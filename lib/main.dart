import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'core/license/license_provider.dart';
import 'core/network/backend_launcher_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/license/screens/activation_screen.dart';
import 'features/shell/screens/main_shell_screen.dart';

class _AppWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    BackendLauncherService.instance.stopBackend();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniciar el backend empaquetado en segundo plano si no está corriendo
  unawaited(BackendLauncherService.instance.ensureBackendRunning());

  // Initialize Intl Spanish locale data
  try {
    await initializeDateFormatting('es_DO', null);
    await initializeDateFormatting('es', null);
  } catch (_) {}

  // Desktop Window Configuration
  await windowManager.ensureInitialized();
  windowManager.addListener(_AppWindowListener());
  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1024, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Custom Windows TitleBar
    title: 'SGGI 2.0 - Gestión de Gimnasio',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Local Storage
  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const SggiApp(),
    ),
  );
}

class SggiApp extends ConsumerWidget {
  const SggiApp({super.key});

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final license = ref.watch(licenseProvider);

    // Si la sesión se cierra o expira mientras hay diálogos abiertos, cerrarlos limpiamente
    ref.listen<AuthState>(authProvider, (previous, next) {
      if ((previous?.isAuthenticated ?? false) && !next.isAuthenticated) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    final Widget home;
    if (!license.isActivated) {
      home = const ActivationScreen();
    } else if (authState.isAuthenticated) {
      home = const MainShellScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SGGI 2.0',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to sleek dark desktop theme
      home: home,
    );
  }
}
