import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/consumer_list_screen.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';
import 'theme/theme.dart';

void main() {
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider()..load(),
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (!settings.isLoaded) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final theme = settings.darkMode
            ? AppTheme.dark('')
            : AppTheme.light('');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Electricity Billing',
          theme: theme,
          darkTheme: AppTheme.dark(''),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const ConsumerListScreen(),
          routes: {SettingsScreen.route: (_) => const SettingsScreen()},
        );
      },
    );
  }
}
