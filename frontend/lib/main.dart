import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/booking_provider.dart';
import 'providers/language_provider.dart';
import 'screens/common/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KissanApp());
}

class KissanApp extends StatelessWidget {
  const KissanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'KissanAI',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: langProvider.textDirection,
                child: child!,
              );
            },
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF10B981), // Agritech rich emerald accent
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF10B981),
                secondary: Color(0xFF06B6D4),
                background: Color(0xFF0F172A),
                surface: Color(0xFF1E293B),
                error: Color(0xFFEF4444),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white70),
                bodyMedium: TextStyle(color: Colors.white60),
              ),
              cardTheme: CardTheme(
                color: Colors.white.withOpacity(0.04),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

