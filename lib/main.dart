import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/store_provider.dart';
import 'data/datasources/local/database_service.dart';
import 'data/datasources/remote/api_service.dart';
import 'data/datasources/remote/auth_service.dart';
import 'data/datasources/local/notification_service.dart';
import 'data/repositories/habit_repository_impl.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await APIService.shared.init();
  await AuthService.shared.init();
  await NotificationService.shared.init();

  final habitRepository = HabitRepositoryImpl(DatabaseService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider(habitRepository)..loadHabits()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider.value(value: AuthService.shared),
      ],
      child: const TributeApp(),
    ),
  );
}
