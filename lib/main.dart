import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/store_provider.dart';
import 'data/datasources/remote/api_service.dart';
import 'data/datasources/remote/auth_service.dart';
import 'data/datasources/local/notification_service.dart';
import 'data/repositories/firestore_user_preferences_repository.dart';
import 'data/repositories/firestore_habit_repository.dart';
import 'data/repositories/firestore_user_repository.dart';
import 'data/repositories/firestore_circle_repository.dart';
import 'data/repositories/firestore_iap_repository.dart';
import 'data/services/pending_invite_service.dart';
import 'domain/repositories/iap_repository.dart';
import 'domain/repositories/user_preferences_repository.dart';
import 'domain/repositories/circle_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/services/week_cycle_manager.dart';
import 'domain/services/engagement_service.dart';
import 'presentation/providers/prayer_list_provider.dart';
import 'presentation/providers/scripture_focus_provider.dart';
import 'presentation/providers/circle_habits_provider.dart';
import 'presentation/providers/encouragement_provider.dart';
import 'presentation/providers/milestone_share_provider.dart';
import 'presentation/providers/circle_habit_milestone_provider.dart';
import 'presentation/providers/weekly_pulse_provider.dart';
import 'presentation/providers/circle_events_provider.dart';
import 'presentation/providers/fruit_portfolio_provider.dart';
import 'presentation/providers/habit_category_provider.dart';
import 'presentation/providers/journal_provider.dart';
import 'presentation/providers/journal_theme_provider.dart';
import 'data/repositories/firestore_fruit_portfolio_repository.dart';
import 'data/repositories/local_habit_category_repository.dart';
import 'data/repositories/firestore_journal_repository.dart';
import 'data/services/media_upload_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence so the app works without a connection.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await APIService.shared.init();
  await AuthService.shared.init();
  await NotificationService.shared.init();

  final habitRepository = FirestoreHabitRepository();
  final userRepository = FirestoreUserRepository();
  final sharedPrefs = await SharedPreferences.getInstance();
  final userPrefs = FirestoreUserPreferencesRepository(
    db: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    cache: sharedPrefs,
  );
  await userPrefs.init();
  // Re-sync on every sign-in (handles reinstall and new-device flows).
  AuthService.shared.addListener(() {
    if (AuthService.shared.isAuthenticated) userPrefs.init();
  });

  final iapRepository = FirestoreIAPRepository();
  final storeProvider = StoreProvider(iapRepository: iapRepository);
  final pendingInviteService = PendingInviteService(sharedPrefs);

  final journalRepository = FirestoreJournalRepository();
  await MediaUploadService.instance.init(sharedPrefs, journalRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<PendingInviteService>.value(value: pendingInviteService),
        Provider<IAPRepository>.value(value: iapRepository),
        Provider<UserPreferencesRepository>.value(value: userPrefs),
        Provider<UserRepository>.value(value: userRepository),
        Provider<WeekCycleManager>(create: (_) => WeekCycleManager(userPrefs)),
        ChangeNotifierProvider<EngagementService>(create: (_) => EngagementService(userPrefs)),
        Provider<CircleRepository>(
            create: (_) => FirestoreCircleRepository()),
        ChangeNotifierProvider<HabitCategoryProvider>(
          create: (_) => HabitCategoryProvider(LocalHabitCategoryRepository())
            ..loadCategories(),
        ),
        ChangeNotifierProvider<FruitPortfolioProvider>(
          create: (_) => FruitPortfolioProvider(
            FirestoreFruitPortfolioRepository(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => HabitProvider(
            habitRepository,
            () => AuthService.shared.isAuthenticated,
            context.read<CircleRepository>(),
            context.read<FruitPortfolioProvider>(),
          )..loadHabits(),
        ),
        ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
        ChangeNotifierProvider.value(value: AuthService.shared),
        ChangeNotifierProvider<PrayerListProvider>(
          create: (context) => PrayerListProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<ScriptureFocusProvider>(
          create: (context) => ScriptureFocusProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<CircleHabitsProvider>(
          create: (context) => CircleHabitsProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<EncouragementProvider>(
          create: (context) => EncouragementProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<MilestoneShareProvider>(
          create: (context) => MilestoneShareProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<CircleHabitMilestoneProvider>(
          create: (context) => CircleHabitMilestoneProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<WeeklyPulseProvider>(
          create: (context) => WeeklyPulseProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<CircleEventsProvider>(
          create: (context) => CircleEventsProvider(context.read<CircleRepository>()),
        ),
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider(journalRepository)..loadEntries(),
        ),
        ChangeNotifierProvider<JournalThemeProvider>(
          create: (_) => JournalThemeProvider()..load(),
        ),
      ],
      child: const MyWalkApp(),
    ),
  );

  // Initialise IAP after the widget tree is up so StoreProvider can
  // call notifyListeners() safely.
  await storeProvider.init();
}
