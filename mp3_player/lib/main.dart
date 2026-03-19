import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'providers/app_provider.dart';
import 'services/audio_player_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbService = DatabaseService();
  await dbService.database;
  
  runApp(Mp3PlayerApp());
}

class Mp3PlayerApp extends StatelessWidget {
  Mp3PlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
      ],
      child: MaterialApp(
        title: 'MP3 播放器',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blue[600],
          scaffoldBackgroundColor: Colors.grey[950],
          colorScheme: ColorScheme.dark(
            primary: Colors.blue[600]!,
            secondary: Colors.blue[400]!,
            surface: Colors.grey[900]!,
            error: Colors.red[400]!,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.grey[850],
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.grey[850],
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            contentTextStyle: TextStyle(color: Colors.grey[300]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.grey[800],
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey[800],
            thickness: 1,
          ),
          iconTheme: IconThemeData(
            color: Colors.grey[400],
          ),
          textTheme: TextTheme(
            headlineLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            headlineMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            bodyLarge: const TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.grey[300]),
            labelLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          useMaterial3: true,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
