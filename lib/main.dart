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
import 'data/datasources/local/shared_preferences_repository.dart';
import 'data/repositories/habit_repository_impl.dart';
import 'data/repositories/circle_repository_impl.dart';
import 'domain/repositories/user_preferences_repository.dart';
import 'domain/repositories/circle_repository.dart';
import 'domain/services/week_cycle_manager.dart';
import 'domain/services/engagement_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await APIService.shared.init();
  await AuthService.shared.init();
  await NotificationService.shared.init();

  final habitRepository = HabitRepositoryImpl(DatabaseService());
  final userPrefs = SharedPreferencesRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<UserPreferencesRepository>.value(value: userPrefs),
        Provider<WeekCycleManager>(create: (_) => WeekCycleManager(userPrefs)),
        ChangeNotifierProvider<EngagementService>(create: (_) => EngagementService(userPrefs)),
        Provider<CircleRepository>(
            create: (_) => CircleRepositoryImpl(APIService.shared)),
        ChangeNotifierProvider(
          create: (context) => HabitProvider(
            habitRepository,
            () => AuthService.shared.isAuthenticated,
            context.read<CircleRepository>(),
          )..loadHabits(),
        ),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider.value(value: AuthService.shared),
      ],
      child: const TributeApp(),
    ),
  );
}
